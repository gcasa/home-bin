#!/usr/bin/env ruby
# frozen_string_literal: true

# file: tools/site_to_pdf.rb
# Recursive Website → PDF for macOS using Playwright (Chromium) — Ruby version
#
# Usage:
#   ruby tools/site_to_pdf.rb https://example.com \
#     --outdir ./pdfs --depth 2 --max-pages 100 --concurrency 4 \
#     --merge ./pdfs/site.pdf --allow-subdomains --no-robots
#
# Install (macOS):
#   brew install ruby
#   gem install playwright-ruby-client combine_pdf robotex
#   npx playwright install chromium   # installs the Chromium runtime used by Playwright
#
# Notes:
# - Run this file with **ruby**, not python.
# - Defaults to same host only; add --allow-subdomains together with --same-domain for *.example.com.
# - Use --no-robots to skip robots.txt checks (not recommended for public sites).
# - PDF header/footer includes URL and page numbers.
# - Combine per-page PDFs into one with --merge PATH.
# - Run tests: `ruby tools/site_to_pdf.rb --selftest`

require 'rubygems'
require 'uri'
require 'set'
require 'fileutils'
require 'optparse'
require 'thread'
require 'timeout'

# Minimal Ruby version guard to avoid odd syntax errors on very old Rubies.
require 'rubygems'
MIN_RUBY = Gem::Version.new('2.6.0')
if Gem::Version.new(RUBY_VERSION) < MIN_RUBY
  abort("Ruby #{MIN_RUBY}+ required. You are running #{RUBY_VERSION}.")
end

# Optional deps loaded lazily for nicer error messages.
begin
  require 'playwright'
rescue LoadError
  Playwright = nil
end
begin
  require 'combine_pdf'
rescue LoadError
  CombinePDF = nil
end
begin
  require 'robotex'
rescue LoadError
  Robotex = nil
end

class CrawlConfig
  attr_accessor :start_url, :outdir, :max_depth, :max_pages, :concurrency,
                :same_host, :allow_subdomains, :include_re, :exclude_re,
                :respect_robots, :merge_path, :timeout_ms, :wait_until,
                :user_agent, :print_background, :format,
                :margin_top, :margin_bottom, :margin_left, :margin_right,
                :viewport_w, :viewport_h

  def initialize(start_url:, outdir: './site-pdfs', max_depth: 2, max_pages: 100,
                 concurrency: 4, same_host: true, allow_subdomains: false,
                 include_re: nil, exclude_re: nil, respect_robots: true,
                 merge_path: nil, timeout_ms: 45_000, wait_until: 'networkidle',
                 user_agent: 'SiteToPDFBot/1.0 (+https://example.invalid)',
                 print_background: true, format: 'A4',
                 margin_top: '16mm', margin_bottom: '16mm',
                 margin_left: '12mm', margin_right: '12mm',
                 viewport_w: 1366, viewport_h: 900)
    @start_url = start_url
    @outdir = outdir
    @max_depth = max_depth
    @max_pages = max_pages
    @concurrency = [1, concurrency.to_i].max
    @same_host = same_host
    @allow_subdomains = allow_subdomains
    @include_re = include_re
    @exclude_re = exclude_re
    @respect_robots = respect_robots
    @merge_path = merge_path
    @timeout_ms = timeout_ms
    @wait_until = wait_until
    @user_agent = user_agent
    @print_background = print_background
    @format = format
    @margin_top = margin_top
    @margin_bottom = margin_bottom
    @margin_left = margin_left
    @margin_right = margin_right
    @viewport_w = viewport_w
    @viewport_h = viewport_h
  end
end

class CrawlState
  attr_reader :root_host, :root_domain, :visited, :enqueued
  attr_accessor :tasks_done

  def initialize(root_host:, root_domain:)
    @root_host = root_host
    @root_domain = root_domain
    @visited = Set.new
    @enqueued = Set.new
    @tasks_done = 0
  end
end

SAFE_EXT_RE = /\.(?:pdf|jpg|jpeg|png|gif|webp|svg|ico|bmp|tiff|mp4|webm|ogg|mp3|wav|zip|gz|tar|rar|7z|dmg|exe|iso)$/i
SCHEME_RE   = /^https?:\/\//i
BAD_SCHEMES = [/^mailto:/i, /^tel:/i, /^javascript:/i, /^data:/i]

# ---------- Utility helpers ----------

def normalize_url(base, href)
  return nil if href.nil? || href.strip.empty?
  return nil if BAD_SCHEMES.any? { |rx| href =~ rx }
  abs = begin
    URI.join(base, href).to_s
  rescue StandardError
    nil
  end
  return nil unless abs && abs =~ SCHEME_RE
  # strip fragment
  u = URI.parse(abs)
  u.fragment = nil
  u.to_s
end


def same_domain?(host, root_domain)
  host == root_domain || host.end_with?(".#{root_domain}")
end


def registrable_domain(host)
  parts = host.split('.')
  parts.length >= 2 ? parts.last(2).join('.') : host
end


def ensure_dir(path)
  FileUtils.mkdir_p(path)
end


def sanitize_filename(s)
  s = s.to_s
  s = s.gsub(/[\s\/\\]+/, '_')
  s = s.gsub(/[^A-Za-z0-9._-]/, '-')
  s = s[0, 200]
  s.empty? ? 'index' : s
end


def url_to_relpath(url)
  u = URI.parse(url)
  path = (u.path.nil? || u.path.empty? || u.path == '/') ? '/index' : u.path.sub(/\/$/, '')
  query = u.query && !u.query.empty? ? "_#{sanitize_filename(u.query)}" : ''
  leaf = sanitize_filename(File.basename(path) + query) + '.pdf'
  if path.count('/') > 1
    dir_parts = path.split('/')
                   .reject(&:empty?)
                   .tap(&:pop)
                   .map { |seg| sanitize_filename(seg) }
    File.join(*(dir_parts + [leaf]))
  else
    leaf
  end
end

# ---------- Robots handling ----------

class Robots
  def initialize(cfg)
    @cfg = cfg
    @robotex = (Robotex.new(@cfg.user_agent) if @cfg.respect_robots && defined?(Robotex))
  end

  def allowed?(url)
    return true unless @cfg.respect_robots
    return true unless @robotex
    # Robotex caches robots.txt; failures default to allowed
    !!@robotex.allowed?(url)
  rescue StandardError
    true
  end
end

# ---------- Crawler ----------

class SiteToPDF
  attr_reader :saved_files, :errors, :state

  def initialize(cfg)
    @cfg = cfg
    parsed = URI.parse(cfg.start_url)
    @state = CrawlState.new(root_host: parsed.host, root_domain: registrable_domain(parsed.host))
    @queue = Queue.new
    @robots = Robots.new(cfg)
    @saved_files = []
    @errors = {}
    @mutex = Mutex.new
  end

  def accept_url?(url)
    u = URI.parse(url)
    return false unless %w[http https].include?(u.scheme)
    return false if u.path =~ SAFE_EXT_RE

    if @cfg.same_host
      return false unless u.host == @state.root_host
    else
      if !@cfg.allow_subdomains
        return false unless u.host == @state.root_host
      else
        return false unless same_domain?(u.host, @state.root_domain)
      end
    end

    return false if @cfg.include_re && !(@cfg.include_re =~ url)
    return false if @cfg.exclude_re && (@cfg.exclude_re =~ url)
    return false unless @robots.allowed?(url)

    true
  rescue URI::InvalidURIError
    false
  end

  def schedule(url, depth)
    @mutex.synchronize do
      return if @state.enqueued.include?(url) || @state.visited.include?(url)
      return if depth > @cfg.max_depth
      return if @state.enqueued.size >= @cfg.max_pages
      return unless accept_url?(url)
      @state.enqueued.add(url)
      @queue << [url, depth]
    end
  end

  def extract_links(page, base_url)
    page.eval_on_selector_all('a[href]', 'elements => elements.map(a => a.getAttribute("href"))')
        .map { |h| normalize_url(base_url, h) }
        .compact
  rescue StandardError
    []
  end

  def save_pdf(page, url)
    rel = url_to_relpath(url)
    out_path = File.join(@cfg.outdir, rel)
    ensure_dir(File.dirname(out_path))

    header_tmpl = "<div style='font-size:8px; width:100%; text-align:center;'></div>"
    footer_tmpl = [
      "<div style='font-size:8px; width:100%; text-align:center;'>",
      '<span class="url"></span> — ',
      '<span class="pageNumber"></span>/<span class="totalPages"></span>',
      '</div>'
    ].join

    page.pdf(
      path: out_path,
      format: @cfg.format,
      print_background: @cfg.print_background,
      display_header_footer: true,
      header_template: header_tmpl,
      footer_template: footer_tmpl,
      margin: { top: @cfg.margin_top, bottom: @cfg.margin_bottom, left: @cfg.margin_left, right: @cfg.margin_right }
    )

    @saved_files << out_path
    out_path
  rescue StandardError => e
    @errors[url] = "pdf_error: #{e.message}"
    nil
  end

  def worker(context)
    page = context.new_page
    page.set_viewport_size(width: @cfg.viewport_w, height: @cfg.viewport_h)
    loop do
      url, depth = @queue.pop
      begin
        @mutex.synchronize do
          next if @state.visited.include?(url)
          @state.visited.add(url)
        end

        begin
          page.goto(url, wait_until: @cfg.wait_until.to_sym, timeout: @cfg.timeout_ms)
        rescue StandardError
          # continue; some pages still render enough for PDF and link extraction
        end

        save_pdf(page, url)
        extract_links(page, url).each { |link| schedule(link, depth + 1) }
      rescue StandardError => e
        @errors[url] = "crawl_error: #{e.message}"
      ensure
        @mutex.synchronize { @state.tasks_done += 1 }
      end
    end
  rescue ThreadError
    # queue closed
  ensure
    page&.close
  end

  def crawl
    raise 'Playwright not installed. See header for install steps.' unless defined?(Playwright) && Playwright

    schedule(@cfg.start_url, 0)

    Playwright.create do |playwright|
      browser = playwright.chromium.launch(headless: true)
      context = browser.new_context(user_agent: @cfg.user_agent)

      threads = Array.new(@cfg.concurrency) { Thread.new { worker(context) } }

      until @queue.empty? || @state.visited.size >= @cfg.max_pages
        sleep 0.05
      end

      threads.each(&:kill)
      threads.each(&:join)

      context.close
      browser.close
    end
  end

  def merge_pdfs
    return nil unless @cfg.merge_path && !@saved_files.empty?
    unless defined?(CombinePDF) && CombinePDF
      warn '[merge] combine_pdf gem not installed; skipping merge'
      return nil
    end
    ensure_dir(File.dirname(@cfg.merge_path))
    combined = CombinePDF.new
    @saved_files.each do |f|
      begin
        combined << CombinePDF.load(f)
      rescue StandardError
        warn "[merge] failed to append #{f}"
      end
    end
    combined.save(@cfg.merge_path)
    @cfg.merge_path
  end
end

# ---------- CLI ----------

def parse_args(argv)
  opts = {
    outdir: './site-pdfs', depth: 2, max_pages: 100, concurrency: 4,
    same_host: true, same_domain: false, allow_subdomains: false,
    include_re: nil, exclude_re: nil, respect_robots: true, merge_path: nil,
    timeout_ms: 45_000, wait_until: 'networkidle', format: 'A4',
    print_background: true, margins: '16mm,16mm,12mm,12mm',
    ua: 'SiteToPDFBot/1.0 (+https://example.invalid)', viewport: '1366x900',
    selftest: false
  }

  parser = OptionParser.new do |o|
    o.banner = 'Usage: ruby tools/site_to_pdf.rb START_URL [options]'
    o.on('--outdir DIR', 'Output directory') { |v| opts[:outdir] = v }
    o.on('--depth N', Integer, 'Max crawl depth') { |v| opts[:depth] = v }
    o.on('--max-pages N', Integer, 'Max pages') { |v| opts[:max_pages] = v }
    o.on('--concurrency N', Integer, 'Workers') { |v| opts[:concurrency] = v }
    o.on('--same-host', 'Limit to exact host (default)') { opts[:same_host] = true }
    o.on('--same-domain', 'Limit to registrable domain') { opts[:same_domain] = true; opts[:same_host] = false }
    o.on('--allow-subdomains', 'Include subdomains when using --same-domain') { opts[:allow_subdomains] = true }
    o.on('--include REGEX', 'Only include URLs matching REGEX') { |v| opts[:include_re] = Regexp.new(v) }
    o.on('--exclude REGEX', 'Exclude URLs matching REGEX') { |v| opts[:exclude_re] = Regexp.new(v) }
    o.on('--no-robots', 'Ignore robots.txt') { opts[:respect_robots] = false }
    o.on('--merge PATH', 'Write a single combined PDF to PATH') { |v| opts[:merge_path] = v }
    o.on('--timeout-ms N', Integer, 'Per-page nav timeout (ms)') { |v| opts[:timeout_ms] = v }
    o.on('--wait-until NAME', ['load','domcontentloaded','networkidle'], 'Wait condition') { |v| opts[:wait_until] = v }
    o.on('--format NAME', 'Paper format') { |v| opts[:format] = v }
    o.on('--no-bg', 'Disable background graphics') { opts[:print_background] = false }
    o.on('--margins A,B,C,D', 'top,bottom,left,right') { |v| opts[:margins] = v }
    o.on('--ua STR', 'User-Agent') { |v| opts[:ua] = v }
    o.on('--viewport WxH', 'Viewport size') { |v| opts[:viewport] = v }
    o.on('--selftest', 'Run built-in unit tests and exit') { opts[:selftest] = true }
  end

  start_url = nil
  begin
    parser.order!(argv) { |nonopt| start_url ||= nonopt }
  rescue OptionParser::ParseError => e
    abort e.message
  end

  if opts[:selftest]
    return [:selftest, opts]
  end

  abort 'start_url is required' unless start_url
  u = URI.parse(start_url) rescue nil
  abort 'start_url must begin with http:// or https://' unless u && %w[http https].include?(u.scheme)

  mt, mb, ml, mr = (opts[:margins] || '').split(',', 4)
  abort "--margins must be 'top,bottom,left,right'" unless [mt,mb,ml,mr].all?

  vw, vh = (opts[:viewport] || '').downcase.split('x', 2)
  abort '--viewport must be WIDTHxHEIGHT, e.g., 1366x900' unless vw && vh && vw.to_i > 0 && vh.to_i > 0

  cfg = CrawlConfig.new(
    start_url: start_url,
    outdir: opts[:outdir],
    max_depth: opts[:depth],
    max_pages: opts[:max_pages],
    concurrency: opts[:concurrency],
    same_host: !opts[:same_domain],
    allow_subdomains: opts[:allow_subdomains],
    include_re: opts[:include_re],
    exclude_re: opts[:exclude_re],
    respect_robots: opts[:respect_robots],
    merge_path: opts[:merge_path],
    timeout_ms: opts[:timeout_ms],
    wait_until: opts[:wait_until],
    user_agent: opts[:ua],
    print_background: opts[:print_background],
    format: opts[:format],
    margin_top: mt.strip,
    margin_bottom: mb.strip,
    margin_left: ml.strip,
    margin_right: mr.strip,
    viewport_w: vw.to_i,
    viewport_h: vh.to_i
  )

  [:run, cfg]
end

# ---------- Unit tests (no network, no browser required) ----------

if ARGV.include?('--selftest')
  require 'minitest/autorun'

  class UnitTests < Minitest::Test
    def test_sanitize_filename
      assert_equal 'a_b_c_d', sanitize_filename('a b/c\\d')
      assert_equal '-', sanitize_filename('*?#')
      assert_equal 'index', sanitize_filename('')
    end

    def test_url_to_relpath
      assert_equal 'index.pdf', url_to_relpath('https://example.com/')
      assert_equal 'docs.pdf', url_to_relpath('https://example.com/docs/')
      assert_equal File.join('a','b.pdf'), url_to_relpath('https://example.com/a/b')
      assert_equal File.join('a','b_x-1-y-2.pdf'), url_to_relpath('https://example.com/a/b?x=1&y=2')
      assert_equal File.join('x','y','z.pdf'), url_to_relpath('https://example.com/x/y/z/')
    end

    def test_normalize_url
      base = 'https://example.com/base/'
      assert_equal 'https://example.com/p', normalize_url(base, '../p')
      assert_nil normalize_url(base, 'mailto:hi@example.com')
      assert_nil normalize_url(base, 'javascript:alert(1)')
      assert_nil normalize_url(base, 'data:text/plain,hi')
      assert_equal 'https://example.com/a', normalize_url('https://example.com#a', '#a')
      assert_nil normalize_url(base, 'ftp://example.com/file')
    end

    def test_same_and_registrable_domain
      assert same_domain?('docs.example.com', 'example.com')
      refute same_domain?('evil.com', 'example.com')
      assert_equal 'example.com', registrable_domain('sub.example.com')
      assert_equal 'localhost', registrable_domain('localhost')
    end

    def test_accept_url_scope_and_filters
      cfg = CrawlConfig.new(start_url: 'https://example.com', outdir: '/tmp', respect_robots: false,
                            include_re: /blog/, exclude_re: /admin/)
      stp = SiteToPDF.new(cfg)
      assert stp.accept_url?('https://example.com/blog/post')
      refute stp.accept_url?('https://example.com/admin/panel')
      refute stp.accept_url?('https://other.com/blog')
      refute stp.accept_url?('https://example.com/file.pdf')
    end
  end
end

# ---------- Main ----------

if __FILE__ == $PROGRAM_NAME
  mode, arg = parse_args(ARGV.dup)
  if mode == :selftest
    # Tests will run via Minitest autorun and control exit status.
  else
    cfg = arg
    FileUtils.mkdir_p(cfg.outdir)

    stp = SiteToPDF.new(cfg)
    begin
      stp.crawl
    rescue Interrupt
      warn 'Interrupted by user'
    end

    merged = stp.merge_pdfs
    puts "Visited: #{stp.state.visited.size} pages; Saved: #{stp.saved_files.size} PDFs"
    unless stp.errors.empty?
      puts "Errors: #{stp.errors.size} (showing up to 10)"
      stp.errors.to_a.first(10).each_with_index do |(u, e), i|
        puts format('  %02d. %s -> %s', i + 1, u, e)
      end
    end
    puts "Merged PDF: #{merged}" if merged
  end
end
