require 'strscan'

class NibCount
  def read_nib
    @data = File.readlines(@name)
  end

  def substring_positions(regexp,substring_len)
    s = StringScanner.new(@data)
    # regexp = Regexp.new(substring)
    positions = []
    positions << (s.pos - substring_len) while s.scan_until(regexp)
    positions
  end

  def enumerate_objects
    result = ""
    regexp = /^\t\t<[a-zA-Z]/
    n = 0
    @data.each do |line|
      found_end = false
      i = regexp.match( line )
      if i.nil? == false
        if n.to_s.length > 3
          line.insert(0, n.to_s) unless i.nil?
          line = line.gsub( "\t\t", "\t" )
        else
          line.insert(1, n.to_s) unless i.nil?
        end
        n = n + 1
      end
      result = result + line
    end
    result
  end

  def write_enum_nib
    f = File.open("/Users/heron/Desktop/MainMenu-enumerated.nib","w")
    f.write(@result)
    f.close
  end

  def execute
    read_nib
    @result = enumerate_objects
    write_enum_nib
  end


  def initialize
    super
    @name = "/Users/heron/Desktop/MainMenu.nib"
  end
end

nc = NibCount.new
nc.execute
