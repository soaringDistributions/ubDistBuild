#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# 2025.08.11 rmh Address occasional build failures due to missing part file asset
# 2025.08.19 rmh Add VM-specific GRUB option 
# 2025.08.22 rmh Fix setting of user PW, fix build action we broke 
# 2025.09.23 rmh Reintroduce missing robust upload support 

###############################################################################
# Robust Upload Support (will need update to ubiquitious_bash or removal)
###############################################################################

# --- Strict timeout: non-zero on timeout, prefer coreutils 'timeout' ---
_timeout_strict() {
  _messagePlain_probe "_timeout_strict → $(printf '%q ' "$@")"
  if command -v timeout >/dev/null 2>&1; then
    # Expected exits:
    #  0: success
    #  124: command timeout
    #  125: timeout command failed 
    #  126/7: command could not run
    #  Other: command exit code 
    _messagePlain_probe "_timeout_strict: coreutils timeout path"
    timeout -k 5 "$@"; local rc=$?
    _messagePlain_probe "_timeout_strict: coreutils rc=$rc"
    return "$rc"
  fi

  _messagePlain_warn "==rmh== **** TEMP _timeout_strict() PATH ***"
  _messagePlain_probe "_timeout_strict: fallback path"
  # path not dynamically tested due to coreutils being present 
  (
    set +b
    local secs rc krc
    secs="$1"; shift
    _messagePlain_probe "_timeout_strict(fb): secs=$(printf '%q' "$secs") cmd=$(printf '%q ' "$@")"
    "$@" & local cmd=$!
    _messagePlain_probe "_timeout_strict(fb): cmd pid=$cmd"
    (
      sleep "$secs"
      # Process should have completed. If not, try to Term/Kill
      if kill -0 "$cmd" 2>/dev/null; then
        _messageWARN "_timeout_strict(fb): timeout fired → TERM pid $cmd"
        kill -TERM "$cmd" 2>/dev/null
        sleep 3
        if kill -0 "$cmd" 2>/dev/null; then
          _messageWARN "_timeout_strict(fb): escalation → KILL $cmd"
          kill -KILL "$cmd" 2>/dev/null
        fi
        exit 124      # value for subprocess - not exposed to function
      fi
      exit 0
    ) & local killer=$!
    _messagePlain_probe "_timeout_strict(fb): killer pid=$killer"

    wait "$cmd"; rc=$?
    _messagePlain_probe "_timeout_strict(fb): cmd exited rc=$rc"

    # learn what the timer did
    if kill -0 "$killer" 2>/dev/null; then
      _messagePlain_probe "_timeout_strict(fb): cancel timer pid=$killer"
      kill -TERM "$killer" 2>/dev/null
      wait "$killer" 2>/dev/null
      krc=0
    else
      wait "$killer"; krc=$?
    fi

    case "$krc" in
      124) _messageWARN "_timeout_strict(fb): timer exited 124 (timeout occurred)";;
      0)   _messagePlain_probe "_timeout_strict(fb): timer exited 0 (no timeout)";;
      *)   _messageWARN "_timeout_strict(fb): timer exited rc=$krc";;
    esac

    _messagePlain_probe "_timeout_strict(fb): returning rc=$rc"
    exit "$rc"
    # Expected return values
    #  0: success of command 
    #  143: TERMinated
    #  137: KILLed 
    #  Other: command value 
  )
}


# --- helper: check if an asset name exists on a tag ---
_gh_release_asset_present() {
  local currentTag="$1"
  local assetName="$2"
  "$scriptAbsoluteLocation" _timeout_strict 120 \
    gh release view "$currentTag" --json assets 2>/dev/null \
    | grep -F "\"name\":\"$assetName\"" >/dev/null
}

# --- override: single file uploader with real retries and status ---
_gh_release_upload_part-single_sequence() {
  _messagePlain_nominal '==rmh== _gh_release_upload: '"$1"' '"$2"
  local currentTag="$1"
  local currentFile="$2"

  local currentIteration=0
  local maxIterations=30
  local rc=1
  local assetName
  assetName=$(basename -- "$currentFile")

  while [[ "$currentIteration" -le "$maxIterations" ]]; do
    if "$scriptAbsoluteLocation" _stopwatch \
         _timeout_strict 600 \
         gh release upload --clobber "$currentTag" "$currentFile"
    then
      # Verify asset is visible (eventual consistency guard)
      local vtries=0
      while [[ $vtries -lt 5 ]]; do
        if _gh_release_asset_present "$currentTag" "$assetName"; then
          rc=0
          break
        fi
        sleep 2
        let vtries++
      done
      if [[ $rc -eq 0 ]]; then
        _messagePlain_probe "==rmh== uploaded ✓ $assetName"
        break
      else
        _messageWARN "==rmh== ** gh exited 0 but asset not listed yet; retrying: $assetName"
      fi
    else
      _messageWARN "==rmh== ** upload attempt $((currentIteration+1)) of $maxIterations failed: $assetName"
    fi
    sleep 7
    let currentIteration++
  done

  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** upload failed after retries: $assetName → $currentTag"
  fi
  return "$rc"
}

_gh_release_upload_parts-multiple_sequence() {
  _messagePlain_nominal '==rmh== _gh_release_upload_parts: '"$@"
  local currentTag="$1"; shift

  # keep a copy of the file list for verification later
  local -a __files=( "$@" )

  # parallelism (default 12, can override via UB_GH_UPLOAD_PARALLEL)
  local currentStream_max="${UB_GH_UPLOAD_PARALLEL:-12}"
  local currentStreamNum=0

  # kick off uploads
  local currentFile
  for currentFile in "${__files[@]}"; do
    let currentStreamNum++
    "$scriptAbsoluteLocation" _gh_release_upload_part-single_sequence "$currentTag" "$currentFile" &
    eval local currentStream_${currentStreamNum}_PID="$!"
    _messagePlain_probe_var currentStream_${currentStreamNum}_PID

    while [[ $(jobs | wc -l) -ge "$currentStream_max" ]]; do
      echo; jobs; echo
      sleep 2
      true
    done
  done

  # wait for all background uploads to finish
  local currentStreamPause
  for currentStreamPause in $(seq "1" "$currentStreamNum"); do
    _messagePlain_probe "==rmh==currentStream_${currentStreamPause}_PID= $(eval "echo \$currentStream_${currentStreamPause}_PID")"
    if eval "[[ \$currentStream_${currentStreamPause}_PID != '' ]]"; then
      _messagePlain_probe "==rmh== _pauseForProcess $(eval "echo \$currentStream_${currentStreamPause}_PID")"
      _pauseForProcess        $(eval "echo \$currentStream_${currentStreamPause}_PID")
    fi
  done

  while [[ $(jobs | wc -l) -ge 1 ]]; do
    echo; jobs; echo
    sleep 3
    true
  done
  wait  # reap

  # -------------------------------
  # Settle + verification 
  # -------------------------------

  # expected asset names (basenames only)
  local -a expected_names=()
  local f
  for f in "${__files[@]}"; do
    expected_names+=( "$(basename -- "$f")" )
  done

  # settle: wait until all expected assets become visible on the release
  # tunables: UB_GH_VERIFY_ATTEMPTS (default 15), UB_GH_VERIFY_SLEEP (default 8s)
  local max_attempts="${UB_GH_VERIFY_ATTEMPTS:-15}"
  local sleep_s="${UB_GH_VERIFY_SLEEP:-8}"
  local assets_json attempt=1
  while :; do
    assets_json=$("$scriptAbsoluteLocation" _timeout_strict 180 gh release view "$currentTag" --json assets 2>/dev/null || true)

    # count missing
    local missing_count=0
    local name
    for name in "${expected_names[@]}"; do
      if ! printf '%s' "$assets_json" | grep -F "\"name\":\"$name\"" >/dev/null; then
        missing_count=$((missing_count+1))
      fi
    done

    if [[ $missing_count -eq 0 ]]; then
      _messagePlain_probe "==rmh== all assets visible after attempt $attempt"
      break
    fi
    if [[ $attempt -ge $max_attempts ]]; then
      _messagePlain_probe "==rmh== assets still missing after ${attempt} attempts; proceeding to per-asset retries"
      break
    fi

    _messagePlain_probe "==rmh== waiting for assets to appear (attempt $attempt/${max_attempts}); missing=${missing_count}"
    sleep "$sleep_s"
    attempt=$((attempt+1))
  done

  # per-asset verification with short retries (handles stragglers)
  # tunables: UB_GH_VERIFY_PER_ASSET_ATTEMPTS (default 6), UB_GH_VERIFY_PER_ASSET_SLEEP (default 5s)
  local rc=0
  local per_attempts="${UB_GH_VERIFY_PER_ASSET_ATTEMPTS:-6}"
  local per_sleep="${UB_GH_VERIFY_PER_ASSET_SLEEP:-5}"

  local name ok a
  for name in "${expected_names[@]}"; do
    ok=""
    for a in $(seq 1 "$per_attempts"); do
      assets_json=$("$scriptAbsoluteLocation" _timeout_strict 180 gh release view "$currentTag" --json assets 2>/dev/null || true)
      if printf '%s' "$assets_json" | grep -F "\"name\":\"$name\"" >/dev/null; then
        _messagePlain_probe "==rmh== asset verified: $name"
        ok="true"
        break
      fi
      _messagePlain_probe "==rmh== asset not yet visible ($name), retry ${a}/${per_attempts}"
      sleep "$per_sleep"
    done

    if [[ -z "$ok" ]]; then
      _messageFAIL "==rmh== ** missing asset on release: $name"
      rc=1
    fi
  done

  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** some assets were not uploaded successfully"
  else
    _messagePlain_probe "==rmh== all assets verified successfully"
  fi
  return "$rc"
}

###############################################################################
# Split helpers: ensure chunk files are produced for release uploads
###############################################################################
if declare -f _ubDistBuild_split-tail_procedure >/dev/null 2>&1 \
  && ! declare -f _ubDistBuild_split-tail_procedure__orig >/dev/null 2>&1; then
  eval "$(declare -f _ubDistBuild_split-tail_procedure \
    | sed '1s/_ubDistBuild_split-tail_procedure/_ubDistBuild_split-tail_procedure__orig/')"
fi

_ubDistBuild_split-tail_procedure() {
  local inputPath="$1"
  local chunkSize=1997537280
  local chunkCount=0

  if [[ -z "$inputPath" ]]; then
    _messageFAIL "==rmh== split: no input path provided"
    return 1
  fi

  if [[ ! -e "$inputPath" ]]; then
    _messageFAIL "==rmh== split: missing source $inputPath"
    return 1
  fi

  if [[ ! -s "$inputPath" ]]; then
    _messageFAIL "==rmh== split: source is empty $inputPath"
    return 1
  fi

  local iteration size suffix partPath
  for iteration in $(seq 0 50); do
    if [[ ! -e "$inputPath" ]]; then
      break
    fi

    size=$(stat -c%s -- "$inputPath" 2>/dev/null) || {
      _messageFAIL "==rmh== split: unable to stat $inputPath"
      return 1
    }

    if (( size == 0 )); then
      break
    fi

    printf -v suffix "%02d" "$iteration"
    partPath="${inputPath}.part${suffix}"

    rm -f -- "$partPath"

    if (( size <= chunkSize )); then
      if ! mv -f -- "$inputPath" "$partPath"; then
        _messageFAIL "==rmh== split: failed to move final chunk → $partPath"
        return 1
      fi
      ((chunkCount++))
      break
    fi

    if ! tail -c "$chunkSize" -- "$inputPath" > "$partPath"; then
      _messageFAIL "==rmh== split: failed to write chunk → $partPath"
      return 1
    fi

    if ! truncate -s -"$chunkSize" -- "$inputPath"; then
      _messageFAIL "==rmh== split: failed to truncate source $inputPath"
      return 1
    fi

    ((chunkCount++))
  done

  if [[ -e "$inputPath" && ! -s "$inputPath" ]]; then
    rm -f -- "$inputPath" || true
  fi

  if (( chunkCount == 0 )); then
    _messageFAIL "==rmh== split: no chunks were produced for $inputPath"
    return 1
  fi

  return 0
}



###############################################################################
# Preflight: tear down any stale project mounts/loops so a fresh chroot opens
###############################################################################
_ops_preflight_chroot_clean() {
  _messageNormal '[ops] preflight: cleanup stale chroot (deep)'

  # try the built-ins first (quietly)
  "$scriptAbsoluteLocation" _closeChRoot --force >/dev/null 2>&1 || true
  "$scriptAbsoluteLocation" _removeChRoot           >/dev/null 2>&1 || true

  # 1) anything under our normal live root(s)
  awk -v r="$scriptLocal" '$2 ~ "^"r"/v(/|$)" {print length($2),$2}' /proc/mounts |
    sort -nr | awk '{print $2}' |
    while read -r m; do
      sudo umount "$m" 2>/dev/null || sudo umount -l "$m" 2>/dev/null || true
    done

  # 2) collect this project’s loop devices
  mapfile -t _ops_loops < <(sudo losetup -a | awk -F: -v r="$(pwd)" '$0 ~ r {print $1}')

  # 3) unmount anywhere those loops are mounted
  if ((${#_ops_loops[@]})); then
    awk -v devs="$(printf "|%s" "${_ops_loops[@]}")" '
      BEGIN{split(devs,a,"|")}
      { for(i in a) if(a[i]!="" && $1==a[i]) print length($2),$2 }' /proc/mounts |
      sort -nr | awk '{print $2}' |
      while read -r m; do
        sudo umount "$m" 2>/dev/null || sudo umount -l "$m" 2>/dev/null || true
      done
  fi

  # 4) extra guard: anything under ~/.ubtmp/*/root*
  awk '$2 ~ "/\\.ubtmp/.*/root.*"' /proc/mounts |
    sort -k2,2r -s | awk '{print $2}' |
    while read -r m; do
      sudo umount "$m" 2>/dev/null || sudo umount -l "$m" 2>/dev/null || true
    done

  # 5) now detach the loops
  for L in "${_ops_loops[@]}"; do
    sudo losetup -d "$L" 2>/dev/null || true
  done

  # 6) remove stale breadcrumb that misleads mountimage
  rm -f "$scriptLocal"/imagedev || true
}

###############################################################################
# VBoxGuest defer: unit + loader (triggered only when kernel cmdline requests)
###############################################################################
_here_vboxguest_defer_service() {
cat <<'EOF'
[Unit]
Description=Defer VirtualBox guest until KDE is ready (opt-in)
ConditionVirtualization=oracle
After=display-manager.service sddm.service
Wants=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/vboxguest-defer-load.sh
RemainAfterExit=true
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
WantedBy=graphical.target
EOF
}

_here_vboxguest_defer_script() {
cat <<'EOF'
#!/bin/sh
set -eu

log(){ logger -t vboxguest-defer "$*"; echo "vboxguest-defer: $*"; }

log "start pid=$$"

# Only on VMs (the unit also has ConditionVirtualization)
if ! systemd-detect-virt --quiet --vm; then
  log "not a VM; exit"
  exit 0
fi

# Accept either "vboxguest.defer=1" or a split ".defer=1"
if ! grep -qFw 'vboxguest.defer=1' /proc/cmdline && ! grep -qFw '.defer=1' /proc/cmdline; then
  log "defer flag not present; exit"
  exit 0
fi
log "defer flag detected"

# Already loaded?
if lsmod | awk '{print $1}' | grep -qx vboxguest; then
  log "vboxguest already loaded; exit"
  exit 0
fi

# Wait up to 90s for KDE (X11/Wayland)
i=90
while [ $i -gt 0 ]; do
  pgrep -x plasmashell >/dev/null 2>&1 && break
  pgrep -x kwin_x11    >/dev/null 2>&1 && break
  pgrep -x kwin_wayland>/dev/null 2>&1 && break
  pgrep -x startplasma-x11 >/dev/null 2>&1 && break
  pgrep -x startplasma-wayland >/dev/null 2>&1 && break
  sleep 1; i=$((i-1))
done
[ $i -gt 0 ] && log "KDE detected; proceeding" || log "timeout waiting for KDE; proceeding"

maybe_load() {
  n="$1"
  if modprobe -v "$n" 2>/dev/null; then log "modprobe $n ok"; return 0; fi
  k="$(uname -r)"
  f="$(find "/lib/modules/$k" -type f -name "${n}.ko*" -print -quit 2>/dev/null || true)"
  if [ -n "${f:-}" ] && insmod "$f" 2>/dev/null; then log "insmod $n ok ($f)"; return 0; fi
  log "could not load $n"
  return 1
}

maybe_load vboxguest || true
maybe_load vboxsf    || true
maybe_load vboxvideo || true

udevadm settle --timeout=10 || true

# Nudge whatever VBox service name this distro uses
for unit in vboxservice.service vboxservice VBoxService.service vboxadd-service.service vboxadd.service; do
  if systemctl list-unit-files --no-legend | awk '{print $1}' | grep -qx "$unit"; then
    systemctl try-restart "$unit" || systemctl start "$unit" || true
    log "nudged $unit"
  fi
done

# Per-user helpers (best-effort)
if command -v loginctl >/dev/null 2>&1; then
  for uid in $(loginctl list-users --no-legend | awk '{print $1}'); do
    user="$(id -un "$uid" 2>/dev/null || true)"; [ -n "$user" ] || continue
    su -l "$user" -c 'command -v VBoxClient-all >/dev/null && VBoxClient-all >/dev/null 2>&1 || true' || true
  done
fi

log "loaded modules: $(lsmod | awk '\''$1 ~ /^vbox/ {printf $1" "}'\'')"
log "done"
EOF
}

_install_vboxguest_defer() {
  _messageNormal '[ops] vboxguest defer: installing (late loader)'

  sudo -n mkdir -p "$globalVirtFS"/usr/local/sbin
  sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system/{multi-user.target.wants,graphical.target.wants}

  _here_vboxguest_defer_script  | sudo -n tee "$globalVirtFS"/usr/local/sbin/vboxguest-defer-load.sh >/dev/null
  _chroot chown root:root /usr/local/sbin/vboxguest-defer-load.sh
  _chroot chmod 0755      /usr/local/sbin/vboxguest-defer-load.sh

  _here_vboxguest_defer_service | sudo -n tee "$globalVirtFS"/etc/systemd/system/vboxguest-defer-load.service >/dev/null
  _chroot chown root:root /etc/systemd/system/vboxguest-defer-load.service
  _chroot chmod 0644      /etc/systemd/system/vboxguest-defer-load.service

  _chroot ln -sf /etc/systemd/system/vboxguest-defer-load.service \
                /etc/systemd/system/multi-user.target.wants/vboxguest-defer-load.service || true
  _chroot ln -sf /etc/systemd/system/vboxguest-defer-load.service \
                /etc/systemd/system/graphical.target.wants/vboxguest-defer-load.service   || true
}

###############################################################################
# Offline password setter: no services, set directly inside the build chroot
###############################################################################
_ops_set_pw_offline() {
  # Only if UB_USER_PW is provided by the caller
  if [ -z "${UB_USER_PW:-}" ]; then
    _messageNormal '[ops] live pw: skip (UB_USER_PW not set)'
    return 0
  fi

  # Make sure /etc/ub exists to mark success (and avoid re-do)
  _chroot mkdir -p /etc/ub || true

  # Set for 'user' (and root too, if you want that—comment out if not desired)
  _messageNormal '[ops] live pw: setting user/root in chroot'
  _chroot sh -ceu 'printf "user:%s\n" "$UB_USER_PW" | chpasswd'
  _chroot sh -ceu 'printf "root:%s\n" "$UB_USER_PW" | chpasswd' || true

  echo 'pw:ok' | sudo -n tee "$globalVirtFS"/OPS_MARKER_PW >/dev/null || true
}

###############################################################################
# GRUB: force timeout to 3s AND append VBoxGuest-deferred entries
###############################################################################
# copy the upstream function body so we can wrap it
if declare -f _live_grub_here >/dev/null 2>&1 && ! declare -f _live_grub_here__orig >/dev/null 2>&1; then
  eval "$(declare -f _live_grub_here | sed '1s/_live_grub_here/_live_grub_here__orig/')"
fi

# Track whether we staged a secondary kernel/initrd pair
ub_ops_live_has_lts_kernel=false

# override: emit upstream grub.cfg with timeout forced, then append our entries
_live_grub_here() {
  # 1) force timeout to 3s (put ours at top; drop any existing timeout lines)
  {
    printf '%s\n' 'set timeout=3'
    _live_grub_here__orig | sed -E '/^[[:space:]]*set[[:space:]]+timeout=.*/d'
  }

  # 2) append our VBoxGuest-deferred menuentries
  cat <<'EOF'

menuentry "Live (VBoxGuest deferred)" {
    linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0 modprobe.blacklist=vboxguest vboxguest.defer=1
    initrd /initrd
}
EOF

  if [[ "${ub_ops_live_has_lts_kernel:-false}" == "true" ]]; then
    cat <<'EOF'

menuentry "Live -lts (VBoxGuest deferred)" {
    linux /vmlinuz-lts boot=live config debug=1 noeject nopersistence selinux=0 modprobe.blacklist=vboxguest vboxguest.defer=1
    initrd /initrd-lts
}
EOF
  fi
}

###############################################################################
# Hook into the live ISO build to install defer + set password
###############################################################################
_live() {
  _messagePlain_nominal "==rmh== Live (modified)"

  # ensure the playground is clean before opening the chroot
  _ops_preflight_chroot_clean

  # run the stock sequence (opens chroot)
  if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"; then _stop 1; fi

  # our additions while chroot is open
  _install_vboxguest_defer
  _ops_set_pw_offline

  # build the ISO and write it with our safer out step
  if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"; then
    _stop 1
  fi

  # upstream clean-up
  export safeToDeleteGit="true"
  _safeRMR "$scriptLocal"/livefs
}

###############################################################################
# Replace upstream _live_sequence_in with a single-pass squashfs build
###############################################################################
_live_sequence_in() {
  _messageNormal 'init: _live (ops override single-pass)'

  _mustGetSudo || return 0

  _start
  cd "$safeTmp"

  # Open chroot to regenerate initramfs and capture forensic copies
  _messagePlain_nominal 'Attempt: _openChRoot'
  ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

  _live_preload_here | sudo -n tee "$globalVirtFS"/usr/share/initramfs-tools/scripts/init-bottom/preload_run > /dev/null
  _chroot chown root:root /usr/share/initramfs-tools/scripts/init-bottom/preload_run
  _chroot chmod 755 /usr/share/initramfs-tools/scripts/init-bottom/preload_run

  _chroot update-initramfs -u -k all
  _chroot apt-get -y clean

  # For offline revert info in ISO
  mkdir -p "$safeTmp"/root002
  sudo -n rsync -a --progress --exclude "lost+found" "$globalVirtFS"/boot "$safeTmp"/root002/boot-copy
  sudo -n cp -a "$globalVirtFS"/etc/fstab  "$safeTmp"/root002/fstab-copy

  _messagePlain_nominal 'Attempt: _closeChRoot'
  ! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

  # Fresh livefs workspace
  export safeToDeleteGit="true"
  [[ -e "$scriptLocal"/livefs ]] && _safeRMR "$scriptLocal"/livefs
  [[ -e "$scriptLocal"/livefs ]] && _messageFAIL
  mkdir -p "$scriptLocal"/livefs/partial
  mkdir -p "$scriptLocal"/livefs/image/live

  # Mount image partitions for access to kernels and EFI bits
  _messagePlain_nominal 'Attempt: _openImage'
  ! _openImage && _messageFAIL && _stop 1
  imagedev=$(cat "$scriptLocal"/imagedev)
  if [[ "$ubVirtImageBoot" != "" ]]; then
    sudo -n mkdir -p "$globalVirtFS"/boot
    sudo -n mount "$imagedev""$ubVirtImageBoot" "$globalVirtFS"/boot
  fi
  if [[ "$ubVirtImageEFI" != "" ]]; then
    sudo -n mkdir -p "$globalVirtFS"/boot/efi
    sudo -n mount "$imagedev""$ubVirtImageEFI" "$globalVirtFS"/boot/efi
  fi

  # Stage a complete filesystem tree, then run mksquashfs once
  local STAGE
  STAGE="$safeTmp/live_stage"
  export safeToDeleteGit="true"
  [[ -e "$STAGE" ]] && _safeRMR "$STAGE"
  mkdir -p "$STAGE"

  # Copy everything except boot and fstab; we’ll add forensic copies separately
  sudo -n rsync -a \
    --exclude 'boot' \
    --exclude 'etc/fstab' \
    "$globalVirtFS"/ "$STAGE"/

  # Add forensic helpers (boot-copy, fstab-copy) at top-level
  if [[ -d "$safeTmp"/root002 ]]; then
    sudo -n cp -a "$safeTmp"/root002/boot-copy "$STAGE"/ 2>/dev/null || true
    sudo -n cp -a "$safeTmp"/root002/fstab-copy "$STAGE"/ 2>/dev/null || true
  fi

  _messagePlain_nominal 'mksquashfs: single-pass from staged root'
  _messagePlain_probe_cmd df -h
  if ! _messagePlain_probe_cmd sudo -n mksquashfs "$STAGE" "$scriptLocal"/livefs/image/live/filesystem.squashfs -b 262144 -no-xattrs -noI -noX -comp lzo -Xalgorithm lzo1x_1; then
    _messageFAIL
    _stop 1
    return 1
  fi
  du -sh "$scriptLocal"/livefs/image/live/filesystem.squashfs

  # Copy kernel and initrd into the ISO tree
  ub_ops_live_has_lts_kernel=false
  local -a _kernels _initrds _kernel_candidates _initrd_candidates
  local _have_lts_kernel=false _have_lts_initrd=false

  shopt -s nullglob
  _kernel_candidates=("$globalVirtFS"/boot/vmlinuz-*)
  _initrd_candidates=("$globalVirtFS"/boot/initrd.img-*)
  shopt -u nullglob

  if ((${#_kernel_candidates[@]})); then
    mapfile -t _kernels < <(printf '%s\n' "${_kernel_candidates[@]}" | sort -r -V)
  else
    _kernels=()
  fi
  if ((${#_initrd_candidates[@]})); then
    mapfile -t _initrds < <(printf '%s\n' "${_initrd_candidates[@]}" | sort -r -V)
  else
    _initrds=()
  fi

  if ((${#_kernels[@]} >= 1)); then
    if ! cp "${_kernels[0]}" "$scriptLocal/livefs/image/vmlinuz"; then
      _messagePlain_bad 'fail: copy primary kernel into ISO tree'
      _messageFAIL
      _stop 1
      return 1
    fi
  else
    _messagePlain_bad 'no kernel images found under /boot'
    _messageFAIL
    _stop 1
    return 1
  fi

  if ((${#_kernels[@]} >= 2)); then
    if cp "${_kernels[1]}" "$scriptLocal/livefs/image/vmlinuz-lts"; then
      _have_lts_kernel=true
    else
      _messagePlain_warn 'live: failed to copy secondary kernel; removing vmlinuz-lts'
      rm -f "$scriptLocal/livefs/image/vmlinuz-lts"
      _have_lts_kernel=false
      ub_ops_live_has_lts_kernel=false
    fi
  else
    _messageNormal 'live: secondary kernel missing; skipping vmlinuz-lts'
  fi

  if ((${#_initrds[@]} >= 1)); then
    if ! cp "${_initrds[0]}" "$scriptLocal/livefs/image/initrd"; then
      _messagePlain_bad 'fail: copy primary initrd into ISO tree'
      _messageFAIL
      _stop 1
      return 1
    fi
  else
    _messagePlain_bad 'no initrd images found under /boot'
    _messageFAIL
    _stop 1
    return 1
  fi

  if ((${#_initrds[@]} >= 2)); then
    if cp "${_initrds[1]}" "$scriptLocal/livefs/image/initrd-lts"; then
      _have_lts_initrd=true
    else
      _messagePlain_warn 'live: failed to copy secondary initrd; removing initrd-lts'
      rm -f "$scriptLocal/livefs/image/initrd-lts"
      _have_lts_initrd=false
      ub_ops_live_has_lts_kernel=false
    fi
  else
    _messageNormal 'live: secondary initrd missing; skipping initrd-lts'
  fi

  if [[ "$_have_lts_kernel" == "true" && "$_have_lts_initrd" == "true" ]]; then
    ub_ops_live_has_lts_kernel=true
  else
    ub_ops_live_has_lts_kernel=false
  fi

  if [[ "${ub_ops_live_has_lts_kernel:-false}" != "true" ]]; then
    rm -f "$scriptLocal/livefs/image/vmlinuz-lts" "$scriptLocal/livefs/image/initrd-lts"
  fi

  cp "$globalVirtFS"/boot/tboot* "$scriptLocal"/livefs/image/ 2>/dev/null || true
  cp "$globalVirtFS"/boot/*.bin "$scriptLocal"/livefs/image/  2>/dev/null || true

  _live_grub_here > "$scriptLocal"/livefs/partial/grub.cfg
  touch "$scriptLocal"/livefs/image/ROOT_TEXT

  _messagePlain_nominal 'Attempt: _closeImage'
  sudo -n umount "$globalVirtFS"/boot/efi > /dev/null 2>&1 || true
  sudo -n umount "$globalVirtFS"/boot     > /dev/null 2>&1 || true
  ! _closeImage && _messageFAIL && _stop 1

  # Revert helper and GRUB images
  _write_revert_live

  grub-mkstandalone --format=x86_64-efi --output="$scriptLocal"/livefs/partial/bootx64.efi --locales="" --fonts="" "boot/grub/grub.cfg=$scriptLocal/livefs/partial/grub.cfg"
  cd "$scriptLocal"/livefs/partial
  dd if=/dev/zero of="$scriptLocal"/livefs/partial/efiboot.img bs=1M count=10
  "$(sudo -n bash -c 'type -p mkfs.vfat' || echo /sbin/mkfs.vfat)" "$scriptLocal"/livefs/partial/efiboot.img
  mmd   -i "$scriptLocal"/livefs/partial/efiboot.img efi efi/boot
  mcopy -i "$scriptLocal"/livefs/partial/efiboot.img "$scriptLocal"/livefs/partial/bootx64.efi ::efi/boot/
  cd "$scriptLocal"/livefs

  grub-mkstandalone --format=i386-pc --output="$scriptLocal"/livefs/partial/core.img --install-modules="linux normal iso9660 biosdisk memdisk search tar ls" --modules="linux normal iso9660 biosdisk search" --locales="" --fonts="" "boot/grub/grub.cfg=$scriptLocal/livefs/partial/grub.cfg"
  cat /usr/lib/grub/i386-pc/cdboot.img "$scriptLocal"/livefs/partial/core.img > "$scriptLocal"/livefs/partial/bios.img

  # Cleanup staging
  export safeToDeleteGit="true"
  _safeRMR "$STAGE"
  _safeRMR "$safeTmp"/root002

  _stop 0
}

###############################################################################
# Simpler, robust out step: write directly into _local, then rename/fallback
###############################################################################
_live_sequence_out() {
  [[ ! -e "$scriptLocal"/livefs ]] && _messageFAIL
  _start

  # Compose paths: write the build directly to _local with a unique name
  local ts out_final out_tmp alt
  ts="$(date +%Y%m%d-%H%M%S)"
  out_final="$scriptLocal"/vm-live.iso
  out_tmp="$scriptLocal"/.vm-live.build-${ts}.iso

  # Create ISO (same payload as upstream, but to out_tmp)
  xorriso -as mkisofs \
    -iso-level 3 -full-iso9660-filenames \
    -volid "ROOT_TEXT" \
    -eltorito-boot boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
    -append_partition 2 0xef "$scriptLocal"/livefs/partial/efiboot.img \
    -output "$out_tmp" \
    -graft-points \
      "$scriptLocal"/livefs/image \
      /boot/grub/bios.img="$scriptLocal"/livefs/partial/bios.img \
      /EFI/efiboot.img="$scriptLocal"/livefs/partial/efiboot.img

  # Try to replace vm-live.iso; if it fails (locked/permission), keep a new name
  if mv -f -- "$out_tmp" "$out_final" 2> "$safeTmp/.mv_err"; then
    rm -f "$safeTmp/.mv_err" || true
  else
    alt="$scriptLocal"/vm-live_${ts}.iso
    _messagePlain_warn "[ops] cannot update vm-live.iso; saving as $(basename "$alt")"
    if mv -f -- "$out_tmp" "$alt"; then
      _messagePlain_warn "[ops] kept new image as $(basename "$alt"); old vm-live.iso left unchanged"
      rm -f "$safeTmp/.mv_err" || true
    else
      _messagePlain_warn "[ops] fallback rename also failed; leaving $(basename "$out_tmp")"
      _messagePlain_warn "[ops] see $safeTmp/.mv_err if present"
    fi
  fi

  _messageNormal '_live: done'
  _stop 0
}

###############################################################################
# Also catch the ingredient VM image stage and set the password there, too
###############################################################################
if declare -f _create_ingredientVM_image >/dev/null 2>&1; then
  _create_ingredientVM_image() {
    # debug instrumentation for early build failure
    local __ops_trace_prev_ps4="${PS4-}"
    local __ops_trace_prev_bash_xtracefd_set=0
    local __ops_trace_prev_bash_xtracefd
    if [[ ${BASH_XTRACEFD+x} ]]; then
      __ops_trace_prev_bash_xtracefd="$BASH_XTRACEFD"
      __ops_trace_prev_bash_xtracefd_set=1
    fi
    local __ops_trace_prev_xtrace=0
    case $- in
      *x*) __ops_trace_prev_xtrace=1 ;;
    esac
    BASH_XTRACEFD=2
    PS4='+[ingredientVM ${EPOCHREALTIME}] '
    set -x
    local __ops_trace_restored=0
    __ops_trace_restore() {
      (( __ops_trace_restored )) && return
      __ops_trace_restored=1
      set +x
      PS4="$__ops_trace_prev_ps4"
      if (( __ops_trace_prev_bash_xtracefd_set )); then
        BASH_XTRACEFD="$__ops_trace_prev_bash_xtracefd"
      else
        unset BASH_XTRACEFD
      fi
      trap - RETURN
      if (( __ops_trace_prev_xtrace )); then
        set -x
      fi
    }
    trap '__ops_trace_restore' RETURN

    __ops_step() {
      local __ops_label="$1"
      shift || true
      >&2 printf '[ops] step: %s\n' "$__ops_label"
      "$@"
      local __ops_rc=$?
      if (( __ops_rc != 0 )); then
        >&2 printf '[ops] step failed: %s (rc=%d)\n' "$__ops_label" "$__ops_rc"
      fi
      return "$__ops_rc"
    }

    __ops_step_pipe() {
      local __ops_label="$1"
      local __ops_input="$2"
      shift 2 || true
      >&2 printf '[ops] step: %s\n' "$__ops_label"
      printf '%s\n' "$__ops_input" | "$@"
      local __ops_rc=$?
      if (( __ops_rc != 0 )); then
        >&2 printf '[ops] step failed: %s (rc=%d)\n' "$__ops_label" "$__ops_rc"
      fi
      return "$__ops_rc"
    }

    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_image'

    if ! __ops_step 'mkdir -p "$scriptLocal"' mkdir -p "$scriptLocal"; then
      local __ops_rc=$?
      __ops_trace_restore
      return "$__ops_rc"
    fi

    if [[ -e "$scriptLocal"/"vm-ingredient.img" ]]; then
      _messagePlain_bad 'bad: fail: exists: vm-ingredient.img'
      __ops_trace_restore
      _messageFAIL
      return 1
    fi

    _messagePlain_nominal '_createVMimage-micro'
    unset ubVirtImageOverride
    if ! __ops_step '_createVMimage-micro' _createVMimage-micro "$@"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"

    _messagePlain_nominal '> _openImage'
    if ! __ops_step '_openImage' "$scriptAbsoluteLocation" _openImage; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _openImage'
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    local imagedev
    imagedev=$(cat "$scriptLocal"/imagedev)

    _messagePlain_nominal 'remount: compression'
    if ! __ops_step 'mount -o remount,compress=zstd:15' sudo -n mount -o remount,compress=zstd:15 "$globalVirtFS"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'debootstrap'
    if ! __ops_step 'debootstrap bookworm' sudo -n debootstrap --variant=minbase --arch amd64 bookworm "$globalVirtFS"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'os: globalVirtFS: write: fs'
    cat <<'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/etc/sudoers > /dev/null
#
# This file MUST be edited with the 'visudo' command as root.
#
# Please consider adding local content in /etc/sudoers.d/ instead of
# directly modifying this file.
#
# See the man page for details on how to write a sudoers file.
#
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# This fixes CVE-2005-4890 and possibly breaks some versions of kdesu
# (#1011624, https://bugs.kde.org/show_bug.cgi?id=452532)
Defaults        use_pty

# This preserves proxy settings from user environments of root
# equivalent users (group sudo)
#Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"

# This allows running arbitrary commands, but so does ALL, and it means
# different sudoers have their choice of editor respected.
#Defaults:%sudo env_keep += "EDITOR"

# Completely harmless preservation of a user preference.
#Defaults:%sudo env_keep += "GREP_COLOR"

# While you shouldn't normally run git as root, you need to with etckeeper
#Defaults:%sudo env_keep += "GIT_AUTHOR_* GIT_COMMITTER_*"

# Per-user preferences; root won't have sensible values for them.
#Defaults:%sudo env_keep += "EMAIL DEBEMAIL DEBFULLNAME"

# "sudo scp" or "sudo rsync" should be able to use your SSH agent.
#Defaults:%sudo env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"

# Ditto for GPG agent
#Defaults:%sudo env_keep += "GPG_AGENT_INFO"

# Host alias specification

# User alias specification

# Cmnd alias specification

# User privilege specification
root    ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL

# See sudoers(5) for more information on "@include" directives:

@includedir /etc/sudoers.d
#_____
#Defaults       env_reset
#Defaults       mail_badpass
#Defaults       secure_path="/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Defaults  env_keep += "currentChroot"
Defaults  env_keep += "chrootName"

root    ALL=(ALL:ALL) ALL
#user   ALL=(ALL:ALL) NOPASSWD: ALL
#pi ALL=(ALL:ALL) NOPASSWD: ALL

user ALL=(ALL:ALL) NOPASSWD: ALL

%admin   ALL=(ALL:ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
%wheel   ALL=(ALL:ALL) NOPASSWD: ALL
#%sudo  ALL=(ALL:ALL) ALL

# Important. Prevents possibility of appending to sudoers again by 'rotten_install.sh' .
# End users may delete this long after dist/OS install is done.
#noMoreRotten

CZXWXcRMTo8EmM8i4d

    _messagePlain_nominal '> _closeImage'
    if ! __ops_step '_closeImage' "$scriptAbsoluteLocation" _closeImage; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _closeImage'
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal '> _openChRoot'
    if ! __ops_step '_openChRoot' "$scriptAbsoluteLocation" _openChRoot; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _openChRoot'
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    imagedev=$(cat "$scriptLocal"/imagedev)

    _messagePlain_nominal '> getMost backend'
    export getMost_backend="chroot"
    if ! __ops_step '_set_getMost_backend' _set_getMost_backend "$@"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_set_getMost_backend_debian' _set_getMost_backend_debian "$@"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_test_getMost_backend' _test_getMost_backend "$@"; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'apt'
    if ! __ops_step '_getMost_backend apt-get update' _getMost_backend apt-get update; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall auto-apt-proxy' _getMost_backend_aptGetInstall auto-apt-proxy; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall apt-transport-https' _getMost_backend_aptGetInstall apt-transport-https; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall apt-fast' _getMost_backend_aptGetInstall apt-fast; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'apt: minimal'
    if ! __ops_step '_getMost_backend_aptGetInstall ca-certificates' _getMost_backend_aptGetInstall ca-certificates; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall apt-utils' _getMost_backend_aptGetInstall apt-utils; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall wget' _getMost_backend_aptGetInstall wget; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall aria2 curl gpg' _getMost_backend_aptGetInstall aria2 curl gpg; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall gnupg' _getMost_backend_aptGetInstall gnupg; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall lsb-release' _getMost_backend_aptGetInstall lsb-release; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall xz-utils' _getMost_backend_aptGetInstall xz-utils; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall openssl jq git lz4 bc xxd' _getMost_backend_aptGetInstall openssl jq git lz4 bc xxd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall pv' _getMost_backend_aptGetInstall pv; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall gh' _getMost_backend_aptGetInstall gh; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall p7zip' _getMost_backend_aptGetInstall p7zip; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall p7zip-full' _getMost_backend_aptGetInstall p7zip-full; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall unzip zip' _getMost_backend_aptGetInstall unzip zip; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall lbzip2' _getMost_backend_aptGetInstall lbzip2; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall btrfs-tools' _getMost_backend_aptGetInstall btrfs-tools; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall btrfs-progs' _getMost_backend_aptGetInstall btrfs-progs; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall btrfs-compsize' _getMost_backend_aptGetInstall btrfs-compsize; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall zstd' _getMost_backend_aptGetInstall zstd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step 'sudo rm -f /etc/sudoers' sudo -n rm -f "$globalVirtFS"/etc/sudoers; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall sudo' _getMost_backend_aptGetInstall sudo; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    cat <<'CZXWXcRMTo8EmM8i4d' | sudo -n tee -a "$globalVirtFS"/etc/sudoers > /dev/null
#_____
#Defaults       env_reset
#Defaults       mail_badpass
#Defaults       secure_path="/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Defaults  env_keep += "currentChroot"
Defaults  env_keep += "chrootName"

root    ALL=(ALL:ALL) ALL
#user   ALL=(ALL:ALL) NOPASSWD: ALL
#pi ALL=(ALL:ALL) NOPASSWD: ALL

user ALL=(ALL:ALL) NOPASSWD: ALL

%admin   ALL=(ALL:ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
%wheel   ALL=(ALL:ALL) NOPASSWD: ALL
#%sudo  ALL=(ALL:ALL) ALL

# Important. Prevents possibility of appending to sudoers again by 'rotten_install.sh' .
# End users may delete this long after dist/OS install is done.
#noMoreRotten

CZXWXcRMTo8EmM8i4d

    _messagePlain_nominal 'hostnamectl'
    if ! __ops_step '_getMost_backend_aptGetInstall hostnamectl' _getMost_backend_aptGetInstall hostnamectl; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot hostnamectl set-hostname default' _chroot hostnamectl set-hostname default; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'tzdata, locales'
    if ! __ops_step '_getMost_backend_aptGetInstall tzdata' _getMost_backend_aptGetInstall tzdata; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_getMost_backend_aptGetInstall locales' _getMost_backend_aptGetInstall locales; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step '_getMost_backend_aptGetInstall systemd' _getMost_backend_aptGetInstall systemd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'apt: DEPENDENCIES'
    if ! __ops_step '_getMost_backend_aptGetInstall DEPENDENCIES' _getMost_backend_aptGetInstall fuse expect software-properties-common libvirt-daemon-system libvirt-daemon libvirt-daemon-driver-qemu libvirt-clients man-db; then
      local __ops_rc=$?
      _messagePlain_bad 'bad: FAIL: apt-get install DEPENDENCIES'
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'timedatectl, update-locale, localectl'
    if [[ -e "$globalVirtFS"/usr/share/zoneinfo/America/New_York ]]; then
      if ! __ops_step '_chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime' _chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime; then
        local __ops_rc=$?
        __ops_trace_restore
        _messageFAIL
        return "$__ops_rc"
      fi
    fi

    _messagePlain_nominal 'useradd, usermod'
    if ! __ops_step '_chroot useradd -m user' _chroot useradd -m user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -s /bin/bash root' _chroot usermod -s /bin/bash root; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -s /bin/bash user' _chroot usermod -s /bin/bash user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _rand_passwd() { cat /dev/urandom 2> /dev/null | base64 2> /dev/null | tr -dc 'a-zA-Z0-9' 2> /dev/null | head -c "$1" 2> /dev/null ; }

    local __ops_pw
    __ops_pw="root:$(_rand_passwd 15)"
    if ! __ops_step_pipe '_chroot chpasswd root (15)' "$__ops_pw" _chroot chpasswd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    __ops_pw="root:$(_rand_passwd 32)"
    if ! __ops_step_pipe '_chroot chpasswd root (32)' "$__ops_pw" _chroot chpasswd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    __ops_pw="user:$(_rand_passwd 15)"
    if ! __ops_step_pipe '_chroot chpasswd user (15)' "$__ops_pw" _chroot chpasswd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    __ops_pw="user:$(_rand_passwd 32)"
    if ! __ops_step_pipe '_chroot chpasswd user (32)' "$__ops_pw" _chroot chpasswd; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step '_chroot groupadd users' _chroot groupadd users; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot groupadd disk' _chroot groupadd disk; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -a -G sudo user' _chroot usermod -a -G sudo user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -a -G wheel user' _chroot usermod -a -G wheel user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -a -G disk user' _chroot usermod -a -G disk user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot usermod -a -G users user' _chroot usermod -a -G users user; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'apt: upgrade'
    if ! __ops_step '_chroot apt-get upgrade' _chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    _messagePlain_nominal 'apt: clean'
    if ! __ops_step '_chroot apt-get clean' _chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y clean; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step '_chroot apt-get autoclean' _chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y autoclean; then
      local __ops_rc=$?
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    if [ -n "${UB_USER_PW:-}" ]; then
      # ops: set UB_USER_PW override
      if ! __ops_step '_ops_set_pw_offline' _ops_set_pw_offline; then
        local __ops_rc=$?
        __ops_trace_restore
        return "$__ops_rc"
      fi
    fi

    _messagePlain_nominal '> _closeChRoot'
    if ! __ops_step '_closeChRoot' "$scriptAbsoluteLocation" _closeChRoot; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _closeChRoot'
      __ops_trace_restore
      _messageFAIL
      return "$__ops_rc"
    fi

    return 0
  }
fi
if declare -f _createVMimage >/dev/null 2>&1; then
  _createVMimage() {
    # debug instrumentation for _createVMimage
    local __ops_trace_prev_ps4="${PS4-}"
    local __ops_trace_prev_bash_xtracefd_set=0
    local __ops_trace_prev_bash_xtracefd
    if [[ ${BASH_XTRACEFD+x} ]]; then
      __ops_trace_prev_bash_xtracefd="$BASH_XTRACEFD"
      __ops_trace_prev_bash_xtracefd_set=1
    fi
    local __ops_trace_prev_xtrace=0
    case $- in
      *x*) __ops_trace_prev_xtrace=1 ;;
    esac
    BASH_XTRACEFD=2
    local __ops_trace_prev_ps4_set=0
    if [[ ${PS4+x} ]]; then
      __ops_trace_prev_ps4_set=1
    fi
    PS4='+[_createVMimage ${EPOCHREALTIME}] '
    set -x
    local __ops_trace_prev_return_trap
    __ops_trace_prev_return_trap=$(trap -p RETURN)
    local __ops_trace_prev_exit_trap
    __ops_trace_prev_exit_trap=$(trap -p EXIT)
    local __ops_trace_restored=0
    __ops_trace_restore() {
      (( __ops_trace_restored )) && return
      __ops_trace_restored=1
      set +x
      if (( __ops_trace_prev_ps4_set )); then
        PS4="$__ops_trace_prev_ps4"
      else
        unset PS4
      fi
      if (( __ops_trace_prev_bash_xtracefd_set )); then
        BASH_XTRACEFD="$__ops_trace_prev_bash_xtracefd"
      else
        unset BASH_XTRACEFD
      fi
      if [[ -n "$__ops_trace_prev_return_trap" ]]; then
        eval "$__ops_trace_prev_return_trap"
      else
        trap - RETURN
      fi
      if [[ -n "$__ops_trace_prev_exit_trap" ]]; then
        eval "$__ops_trace_prev_exit_trap"
      else
        trap - EXIT
      fi
      if (( __ops_trace_prev_xtrace )); then
        set -x
      fi
    }
    trap '__ops_trace_restore' RETURN
    trap '__ops_trace_restore' EXIT

    __ops_step() {
      local __ops_label="$1"
      shift || true
      >&2 printf '[ops] step: %s\n' "$__ops_label"
      "$@"
      local __ops_rc=$?
      if (( __ops_rc != 0 )); then
        >&2 printf '[ops] step failed: %s (rc=%d)\n' "$__ops_label" "$__ops_rc"
      fi
      return "$__ops_rc"
    }

    _messageNormal '##### _createVMimage'

    if ! __ops_step 'mkdir -p "$scriptLocal"' mkdir -p "$scriptLocal"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    export vmImageFile="$scriptLocal"/vm.img
    [[ "$ub_vmImage_micro" == "true" ]] && export vmImageFile="$scriptLocal"/vm-ingredient.img
    [[ "$ubVirtImageOverride" != "" ]] && export vmImageFile="$ubVirtImageOverride"

    if [[ "$ubVirtImageOverride" == "" ]] && [[ -e "$vmImageFile" ]]; then
      _messagePlain_good 'exists: '"$vmImageFile"
      return 0
    fi
    if [[ "$ubVirtImageOverride" == "" ]] && [[ -e "$scriptLocal"/vm.img ]]; then
      _messagePlain_good 'exists: '"$scriptLocal"/vm.img
      return 0
    fi

    if ! __ops_step 'check lock_open absent' test ! -e "$lock_open"; then
      local __ops_rc=$?
      _messagePlain_bad 'bad: locked!'
      _messageFAIL
      __ops_trace_restore
      _stop 1
      return "$__ops_rc"
    fi
    if ! __ops_step 'check l_o absent' test ! -e "$scriptLocal"/l_o; then
      local __ops_rc=$?
      _messagePlain_bad 'bad: locked!'
      _messageFAIL
      __ops_trace_restore
      _stop 1
      return "$__ops_rc"
    fi

    if [[ "$ubVirtImageOverride" == "" ]]; then
      if ! __ops_step 'check free space >=25GiB' bash -c '[[ $(df --block-size=1000000000 --output=avail "$1" | tr -dc "0-9") -gt 25 ]]' _ "$scriptLocal"; then
        local __ops_rc=$?
        # rmh Diagnostic output for low disk space 
        _messagePlain_bad "bad: need >=25GiB free space"
        df --block-size=1000000000 "."
        df --block-size=1000000000 "$scriptLocal"
        lscpu
        free -h
        df -h /
        df -h 
        _messageFAIL
        __ops_trace_restore
        _stop 1
        return "$__ops_rc"
      fi
    fi

    local imagedev

    if ! __ops_step '_open' _open; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    export vmImageFile="$scriptLocal"/vm.img
    [[ "$ub_vmImage_micro" == "true" ]] && export vmImageFile="$scriptLocal"/vm-ingredient.img
    [[ "$ubVirtImageOverride" != "" ]] && export vmImageFile="$ubVirtImageOverride"

    if [[ "$ubVirtImageOverride" == "" ]]; then
      if ! __ops_step 'check vm image missing' test ! -e "$vmImageFile"; then
        local __ops_rc=$?
        _messagePlain_bad 'exists: '"$vmImageFile"
        _messageFAIL
        __ops_trace_restore
        _stop 1
        return "$__ops_rc"
      fi

      _messageNormal 'create: '"$vmImageFile"': file'

      export vmSize=$(_vmsize)
      [[ "$ub_vmImage_micro" == "true" ]] && export vmSize=$(_vmsize-micro)

      export vmSize_boundary=$(bc <<< "$vmSize - 1")
      if ! __ops_step '_createRawImage "$vmImageFile"' _createRawImage "$vmImageFile"; then
        local __ops_rc=$?
        _messageFAIL
        return "$__ops_rc"
      fi
    else
      _messageNormal 'create: '"$vmImageFile"': device'

      export vmSize=$(bc <<< $(sudo -n lsblk -b --output SIZE -n -d "$vmImageFile")' / 1048576')
      export vmSize=$(bc <<< "$vmSize - 1")
      export vmSize_boundary=$(bc <<< "$vmSize - 1")
    fi

    _messageNormal 'partition: '"$vmImageFile"''
    if ! __ops_step "parted mklabel" sudo -n parted --script "$vmImageFile" 'mklabel gpt'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    export ubVirtImage_doNotOverride="true"
    export ubVirtPlatformOverride='x64-efi'
    export ubVirtImageBIOS=p1
    export ubVirtImageEFI=p2
    export ubVirtImageNTFS=
    export ubVirtImageRecovery=
    export ubVirtImageSwap=p3
    export ubVirtImageBoot=p4
    export ubVirtImagePartition=p5

    if ! __ops_step 'parted bios mkpart' sudo -n parted --script "$vmImageFile" 'mkpart primary ext2 1MiB 2MiB'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted bios flag' sudo -n parted --script "$vmImageFile" 'set 1 bios_grub on'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted efi mkpart' sudo -n parted --script "$vmImageFile" 'mkpart EFI fat32 2MiB 42MiB'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted efi msftdata' sudo -n parted --script "$vmImageFile" 'set 2 msftdata on'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted efi boot' sudo -n parted --script "$vmImageFile" 'set 2 boot on'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted efi esp' sudo -n parted --script "$vmImageFile" 'set 2 esp on'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted swap mkpart' sudo -n parted --script "$vmImageFile" 'mkpart primary 42MiB 44MiB'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted boot mkpart' sudo -n parted --script "$vmImageFile" 'mkpart primary 44MiB 770MiB'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted root mkpart' sudo -n parted --script "$vmImageFile" "mkpart primary 770MiB ${vmSize_boundary}MiB"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if ! __ops_step 'parted print' sudo -n parted --script "$vmImageFile" 'unit MiB print'; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step '_close' _close; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    _messageNormal 'format: '"$vmImageFile"''
    if ! __ops_step '_openLoop' "$scriptAbsoluteLocation" _openLoop; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _openLoop'
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step 'mkdir -p "$globalVirtFS"' mkdir -p "$globalVirtFS"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi
    if __ops_step '_checkForMounts "$globalVirtFS"' "$scriptAbsoluteLocation" _checkForMounts "$globalVirtFS"; then
      _messagePlain_bad 'bad: mounted: globalVirtFS'
      _messageFAIL
      __ops_trace_restore
      _stop 1
      return 1
    fi
    imagedev=$(cat "$scriptLocal"/imagedev)

    local imagepart
    local loopdevfs

    imagepart="$imagedev""$ubVirtImageBoot"
    loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
    [[ "$loopdevfs" == "ext4" ]] && __ops_trace_restore && _stop 1
    if ! __ops_step 'mkfs.ext2 boot' sudo -n mkfs.ext2 -e remount-ro -E lazy_itable_init=0,lazy_journal_init=0 -m 0 "$imagepart"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    imagepart="$imagedev""$ubVirtImageEFI"
    loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
    [[ "$loopdevfs" == "ext4" ]] && __ops_trace_restore && _stop 1
    if ! __ops_step 'mkfs.vfat EFI' sudo -n mkfs.vfat -F 32 -n EFI "$imagepart"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    imagepart="$imagedev""$ubVirtImagePartition"
    loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
    [[ "$loopdevfs" == "ext4" ]] && __ops_trace_restore && _stop 1
    if ! __ops_step 'mkfs.btrfs root' sudo -n mkfs.btrfs --checksum xxhash -M -d single "$imagepart"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    imagepart="$imagedev""$ubVirtImageSwap"
    loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
    [[ "$loopdevfs" == "ext4" ]] && __ops_trace_restore && _stop 1
    if ! __ops_step 'mkswap' sudo -n mkswap "$imagepart"; then
      local __ops_rc=$?
      _messageFAIL
      return "$__ops_rc"
    fi

    if ! __ops_step '_closeLoop' "$scriptAbsoluteLocation" _closeLoop; then
      local __ops_rc=$?
      _messagePlain_bad 'fail: _closeLoop'
      _messageFAIL
      return "$__ops_rc"
    fi
    return 0
  }
fi

