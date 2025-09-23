#!/usr/bin/env bash
# File: scripts/tm-remote-setup.sh
# Purpose: Configure a remotely mounted volume (generic SMB/AFP/NFS share) as a Time Machine destination
# Usage:
#   ./tm-remote-setup.sh \
#     --share-url "smb://user@host/share"        # optional; script can mount via Finder if provided
#     --mount "/Volumes/Share"                   # alternatively, pass an already-mounted path
#     --size 2t                                   # required, sparsebundle max size (e.g., 500g, 2t)
#     [--volname "Time Machine Backups"]         # optional, default "Time Machine Backups"
#     [--fs apfs|hfs]                             # optional, default apfs; use hfs for older macOS
#     [--encrypt]                                 # optional, create encrypted sparsebundle (prompt)
#     [--bundle-name "MyMac.backupbundle"]       # optional, default derived from ComputerName
#     [--inherit "/path/to/existing.sparsebundle"] # optional, claim an existing bundle for this Mac
#
# Notes:
# - This script mounts/creates a sparsebundle image on the remote share, then points Time Machine at the
#   mounted image volume via `tmutil setdestination`.
# - `tmutil` requires Full Disk Access for the Terminal app. Grant it in System Settings > Privacy & Security.
# - APFS in sparsebundles is supported on modern macOS; choose HFS+J with `--fs hfs` for legacy systems.
# - The share must be writable and stable (prefer Ethernet). Quota the bundle by the `--size` you choose.
#
# Minimal dependencies: macOS (hdiutil, tmutil), optional osascript for URL mounting.
#
set -euo pipefail

# ------------------------- helpers -------------------------
log() { printf "[tm-remote-setup] %s\n" "$*"; }
warn() { printf "[tm-remote-setup][WARN] %s\n" "$*" >&2; }
err() { printf "[tm-remote-setup][ERROR] %s\n" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "Missing dependency: $1"; }

default_volname="Time Machine Backups"
default_fs="apfs"
share_url=""
mount_path=""
size=""
volname="$default_volname"
fs="$default_fs"
encrypt=false
bundle_name=""  # may include/omit extension; we'll normalize to .sparsebundle
inherit_path=""

# ------------------------- args ---------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --share-url)      share_url=${2:-}; shift 2;;
    --mount)          mount_path=${2:-}; shift 2;;
    --size)           size=${2:-}; shift 2;;
    --volname)        volname=${2:-}; shift 2;;
    --fs)             fs=${2:-}; shift 2;;
    --encrypt)        encrypt=true; shift;;
    --bundle-name)    bundle_name=${2:-}; shift 2;;
    --inherit)        inherit_path=${2:-}; shift 2;;
    -h|--help)        sed -n '1,80p' "$0"; exit 0;;
    *)                err "Unknown arg: $1";;
  esac
done

[[ -z "$size" ]] && err "--size is required (e.g., 2t or 500g)."

need hdiutil
need tmutil

# --------------------- validate fs ------------------------
case "$fs" in
  apfs|APFS) fs_flag="APFS";;
  hfs|HFS|hfs+|hfsj) fs_flag="HFS+J";;
  *) err "--fs must be 'apfs' or 'hfs'";;
esac

# -------------------- mount share -------------------------
if [[ -n "$share_url" && -n "$mount_path" ]]; then
  warn "Both --share-url and --mount provided; using --mount and ignoring URL."
fi

if [[ -z "$mount_path" ]]; then
  if [[ -z "$share_url" ]]; then
    err "Provide either --mount /Volumes/Share or --share-url smb://user@host/share"
  fi
  log "Mounting share via Finder (you may be prompted for credentials)..."
  # Use Finder to mount so creds can be provided via GUI & stored in Keychain
  osascript -e "try" \
            -e "mount volume \"$share_url\"" \
            -e "end try" >/dev/null || true
  # Wait for a new /Volumes entry to appear
  sleep 2
  # Heuristic: pick the newest mount under /Volumes
  newest=$(ls -1t /Volumes 2>/dev/null | head -n1 || true)
  [[ -z "$newest" ]] && err "Failed to detect mounted share under /Volumes. Specify --mount explicitly."
  mount_path="/Volumes/$newest"
  log "Using mount path: $mount_path"
fi

[[ -d "$mount_path" ]] || err "Mount path not found: $mount_path"
[[ -w "$mount_path" ]] || err "Mount path is not writable: $mount_path"

# ---------------- derive bundle name ----------------------
if [[ -z "$bundle_name" ]]; then
  comp_name=$(scutil --get ComputerName 2>/dev/null || hostname)
  bundle_name="$comp_name"
fi
# Normalize: ensure final path ends with .sparsebundle (avoid double extensions)
base_name="$bundle_name"
base_name="${base_name%.sparsebundle}"
base_name="${base_name%.backupbundle}"
bundle_name="$base_name.sparsebundle"

bundle_path="$mount_path/$bundle_name"

# If an existing non-canonical directory exists (e.g., .backupbundle or .backupbundle.sparsebundle), prefer it
if [[ ! -e "$bundle_path" ]]; then
  for alt in \
      "$mount_path/$base_name.backupbundle.sparsebundle" \
      "$mount_path/$base_name.backupbundle"; do
    if [[ -e "$alt" ]]; then
      warn "Found existing bundle at non-canonical path: $alt; using it."
      bundle_path="$alt"
      break
    fi
  done
fi

if [[ -e "$bundle_path" && -z "$inherit_path" ]]; then
  warn "Bundle already exists: $bundle_path"
  read -r -p "Reuse it? [y/N]: " yn
  if [[ ! "$yn" =~ ^[Yy]$ ]]; then
    err "Refusing to overwrite existing bundle. Use --bundle-name to pick a different name."
  fi
fi

# ------------------- create bundle ------------------------

create_sparsebundle() {
  local dest_path="$1"; shift
  local enc_flag=( )
  if $encrypt; then enc_flag=(-stdinpass -encryption AES-256); fi
  log "Creating sparsebundle ($fs_flag, size=$size): $dest_path"
  if $encrypt; then
    printf "%s" "$pass" | hdiutil create -size "$size" -type SPARSEBUNDLE -fs "$fs_flag" \
      -volname "$volname" -nospotlight "${enc_flag[@]}" "$dest_path"
  else
    hdiutil create -size "$size" -type SPARSEBUNDLE -fs "$fs_flag" \
      -volname "$volname" -nospotlight "$dest_path"
  fi
}

if [[ ! -e "$bundle_path" ]]; then
  # If APFS-over-SMB can't be created directly (e.g., "RPC version wrong"), fall back to local-create+copy.
  # Some NAS/Samba configs lack Apple SMB extensions needed for DiskImages creation. Creating locally then copying works. 
  errfile=$(mktemp -t tm_create_err.XXXX)
  pass="${pass:-}"  # ensure var exists if not encrypt
  set +e
  create_sparsebundle "$bundle_path" 2>"$errfile"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    warn "Direct create failed (exit $rc). $(tr -d '
' < "$errfile" | head -c 200)"
    tmp_bundle="${TMPDIR:-/tmp}/$(basename "$bundle_path").tmp.sparsebundle"
    log "Workaround: creating locally, then copying to the share..."
    set +e
    create_sparsebundle "$tmp_bundle" 2>>"$errfile"
    rc_local=$?
    set -e
    if [[ $rc_local -ne 0 ]]; then
      # Last-resort: try HFS+J image if APFS was requested and creation failed
      if [[ "$fs_flag" == "APFS" ]]; then
        warn "APFS image creation failed; trying HFS+J fallback (more compatible on some NAS)."
        fs_flag="HFS+J"
        set +e
        create_sparsebundle "$tmp_bundle" 2>>"$errfile"
        rc_local=$?
        set -e
      fi
    fi

    if [[ $rc_local -ne 0 ]]; then
      cat "$errfile" >&2 || true
      rm -f "$errfile"
      err "Failed to create sparsebundle (even with local/fallback). See errors above."
    fi

    # Copy bundle to remote share
    log "Copying bundle to $bundle_path (this may take a while)..."
    /usr/bin/ditto "$tmp_bundle" "$bundle_path"
    rm -rf "$tmp_bundle"
    log "Bundle copied to remote share."
  fi
  rm -f "$errfile"
  [[ -n "${pass:-}" ]] && unset pass
else
  log "Using existing sparsebundle: $bundle_path"
fi

# ------------------- attach bundle ------------------------

# Mount to a predictable mount point, falling back to hdiutil default if taken
mount_point="/Volumes/$volname"
if [[ -e "$mount_point" ]]; then
  mount_point="/Volumes/${volname}-TM"
fi

log "Attaching bundle at: $mount_point"
hdiutil attach -mountpoint "$mount_point" "$bundle_path" >/dev/null

# ------------------ tmutil configure ----------------------
log "Setting Time Machine destination to: $mount_point"
if ! sudo -n true 2>/dev/null; then
  warn "sudo needed; you may be prompted for your password."
fi

# tmutil often needs Full Disk Access; warn if it fails with a permissions error
set +e
sudo tmutil setdestination -a "$mount_point" 2>tmutil.err
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  cat tmutil.err >&2 || true
  if grep -qi "Full Disk Access" tmutil.err 2>/dev/null; then
    warn "Grant Full Disk Access to Terminal, then re-run."
  fi
  rm -f tmutil.err
  err "tmutil setdestination failed (exit $rc)."
fi
rm -f tmutil.err

# ------------------ inherit (optional) --------------------
if [[ -n "$inherit_path" ]]; then
  if [[ -e "$inherit_path" ]]; then
    log "Claiming existing backup for this Mac: $inherit_path"
    sudo tmutil inheritbackup "$inherit_path"
  else
    warn "--inherit path does not exist: $inherit_path (skipping)"
  fi
fi

# ------------------ kick off backup -----------------------
log "Starting first backup in automatic mode..."
sudo tmutil startbackup --auto || warn "Could not start backup automatically; start it from System Settings > Time Machine."

log "Current destinations:"
/usr/bin/tmutil destinationinfo || true

log "Done. The sparsebundle will auto-mount when backups run. Keep the network share available."
