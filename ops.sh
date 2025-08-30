#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# 2025.08.11 rmh Address occasional build failures due to missing part file asset
# 2025.08.19 rmh Add VM-specific GRUB option 

# #############################################################################
# #### GRUBB Option ###########################################################
# #### rmh #### Below functions for branch feature/VmReliableBoot ####

# --- banner so you can see ops.sh got sourced in the build log ---
_messageNormal '[ops] vboxguest defer: overrides loaded'

# TEMPORARY PW HANDLING #######################################################
# Recreate iso with > UB_USER_PW='YourNewPassword!' ./ubiquitous_bash.sh _live

_ops_set_live_user_pw_offline() {
  if [ -z "${UB_USER_PW:-}" ]; then
    _messageNormal '[ops] skip: UB_USER_PW not set'
    return 0
  fi
  [ -f "$globalVirtFS/etc/shadow" ] || { _messageNormal "[ops] ERROR: missing $globalVirtFS/etc/shadow"; return 1; }

  _messageNormal '[ops] live pw: setting via chpasswd -R (offline)'
  # Set just 'user'; uncomment root if you want it too.
  printf 'user:%s\n' "$UB_USER_PW" | sudo -n chpasswd -R "$globalVirtFS"
  # printf 'root:%s\n' "$UB_USER_PW" | sudo -n chpasswd -R "$globalVirtFS"

  echo 'pw:offline:ok' | sudo -n tee "$globalVirtFS/OPS_MARKER_PW" >/dev/null
}



# #############################################################################
# ---- debug wrapper around _openChRoot (logs, then passes through) ----
eval "$(declare -f _openChRoot | sed '1s/_openChRoot/_openChRoot__orig/')"
_openChRoot() {
  _messageNormal '[ops] debug: entering _openChRoot'
  {
    echo "----- $(date -Is) (_openChRoot debug) -----"
    echo "whoami: $(whoami)"
    echo "scriptLocal: $scriptLocal"
    echo "globalVirtFS: $globalVirtFS"
    echo "ubVirtPlatform: $ubVirtPlatform"
    echo "mounts before:"; mount | sed 's/^/  /'; echo
  } >> "$scriptLocal/_openChRoot.debug" 2>&1

  set -o pipefail
  # comment next line if debugging not needed 
  # ( set -x; _openChRoot__orig "$@" ) >> "$scriptLocal/_openChRoot.debug" 2>&1
  local rc=$?
  echo "rc=${rc}" >> "$scriptLocal/_openChRoot.debug"
  _messageNormal "[ops] debug: _openChRoot rc=${rc}"

  # If chroot is up, perform idempotent installs once
  if [ $rc -eq 0 ] && [ -n "${globalVirtFS:-}" ] && [ -d "$globalVirtFS" ]; then
    if [ ! -e "$globalVirtFS/.ops_installed" ]; then
      _install_vboxguest_defer || true
      _install_liveconfig_pw_hook || true
      sudo -n touch "$globalVirtFS/.ops_installed" || true
    fi
  fi
  return $rc
}

# Inter-build cleanup #########################################################
# Eliminate hold-over mounts if last _live exection was terminiated or otherwise didn't close cleanly 
_ops_preflight_chroot_clean() {
  _messageNormal '[ops] preflight: cleanup stale chroot (deep)'

  # try the built-ins first
  "$scriptAbsoluteLocation" _closeChRoot --force >/dev/null 2>&1 || true
  "$scriptAbsoluteLocation" _removeChRoot           >/dev/null 2>&1 || true

  # 1) anything under our normal live root(s)
  local root="$scriptLocal"/v/fs
  awk -v r="$scriptLocal" '$2 ~ "^"r"/v(/|$)" {print length($2),$2}' /proc/mounts |
    sort -nr | awk '{print $2}' |
    while read -r m; do
      sudo umount "$m" 2>/dev/null || sudo umount -l "$m" 2>/dev/null || true
    done

  # 2) collect this project’s loop devices
  mapfile -t _ops_loops < <(sudo losetup -a | awk -F: -v r="$(pwd)" '$0 ~ r {print $1}')

  # 3) unmount *anywhere* those loops are mounted (incl. ~/.ubtmp/.../root*)
  if ((${#_ops_loops[@]})); then
    # by device
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
  rm -f "$scriptLocal"/imagedev

  # (optional) quick visibility
  _messagePlain_probe_cmd 'mount | grep -E "_local/(v/fs|v/.*/fs)|\\.ubtmp/.*/root" || echo "no project mounts"'
  _messagePlain_probe_cmd 'sudo losetup -a | grep "$(pwd)" || echo "no project loop devices"'
}

# --- prevent accidental mksquashfs append by removing stale outputs ---
_ops_clear_stale_squashfs() {
  local liveDir="$scriptLocal/livefs/image/live"
  local fs="$liveDir/filesystem.squashfs"

  # remove any old squashfs + recovery files
  [ -e "$fs" ] && rm -f "$fs"
  sudo rm -f /root/squashfs_recovery_filesystem.squashfs_* 2>/dev/null || true

  # blow away the target "live" dir to avoid duplicate entries like 'home_1'
  [ -d "$liveDir" ] && rm -rf "$liveDir"
}


# MESSAGE FUNCTIONS ###########################################################
# eval "$(declare -f _messagePlain_probe_cmd | sed '1s/_messagePlain_probe_cmd/_messagePlain_probe_cmd__orig/')"
# replace eval() with explicitly declared function (and correct typo)
# -- plain copy of the original diagnostic helper --
_messagePlain_probe_cmd_orig() {
  _color_begin_probe
  _safeEcho "$@"
  _color_end
  echo
  if [ $# -eq 1 ]; then
    eval "$1"        # supports pipelines
  else
    "$@"             # preserves argument quoting (e.g. home/*)
  fi
}

# ---- patch the final mksquashfs call to close off /home duplication ----
# We only change the "globalVirtFS" pass: sudo -n mksquashfs "$globalVirtFS" ...
_messagePlain_probe_cmd() {
  # Detect: sudo -n mksquashfs <SRC> <DEST> ...  where <SRC> == "$globalVirtFS"
  if [ "$1" = "sudo" ] && [ "$2" = "-n" ] && [ "$3" = "mksquashfs" ] && [ "$4" = "$globalVirtFS" ]; then
    echo "[TRACE] mksquashfs override: $@" >&2
    # Keep original args and *append* stronger excludes for /home
    _messagePlain_probe_cmd_orig "$@" -wildcards -e 'home/*'
    return $?
  fi
  _messagePlain_probe_cmd_orig "$@"
}

# VBOX Guest Loading Delay ####################################################
# --- unit file content ---
_here_vboxguest_defer_service() {
cat <<'EOF'
[Unit]
Description=Defer vboxguest until after KDE session is up (only if requested)
ConditionKernelCommandLine=vboxguest.defer=1
After=sddm.service graphical.target
Wants=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/vboxguest-defer-load.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
}

# --- loader script (only runs when vboxguest.defer=1 is on cmdline) ---
_here_vboxguest_defer_script() {
cat <<'EOF'
#!/bin/sh
set -eu

# Only on VMs
systemd-detect-virt --quiet --vm || exit 0

# Only when requested via GRUB flag + blacklist
grep -qw 'vboxguest.defer=1' /proc/cmdline || exit 0

# Already loaded? nothing to do
lsmod | awk '{print $1}' | grep -qx vboxguest && exit 0

# Wait up to 90s for KDE session (best-effort)
i=90
while [ $i -gt 0 ]; do
  pgrep -x plasmashell >/dev/null 2>&1 && break
  pgrep -x startplasma-x11 >/dev/null 2>&1 && break
  sleep 1; i=$((i-1))
done

# Load kernel bits; ignore if not present
modprobe -v vboxguest   || true
modprobe -v vboxsf      || true
modprobe -v vboxvideo   || true

udevadm settle || true
systemctl restart vboxservice 2>/dev/null || true

# Nudge per-user helpers (usually autostart anyway)
for uid in $(loginctl list-users --no-legend | awk '{print $1}'); do
  user="$(id -un "$uid" 2>/dev/null || true)"; [ -n "$user" ] || continue
  su -l "$user" -c 'command -v VBoxClient-all >/dev/null && VBoxClient-all >/dev/null 2>&1 || true' || true
done
EOF
}

# --- installer: creates dirs, writes files, enables unit (symlink) ---
_install_vboxguest_defer() {
  _messageNormal '[ops] vboxguest defer: installing (late loader)'

  # Make sure target dirs exist in the live root
  sudo -n mkdir -p "$globalVirtFS"/usr/local/sbin
  sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system
  sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system/multi-user.target.wants

  # Script
  _here_vboxguest_defer_script | sudo -n tee "$globalVirtFS"/usr/local/sbin/vboxguest-defer-load.sh >/dev/null
  _chroot chown root:root /usr/local/sbin/vboxguest-defer-load.sh
  _chroot chmod 0755 /usr/local/sbin/vboxguest-defer-load.sh

  # Unit
  _here_vboxguest_defer_service | sudo -n tee "$globalVirtFS"/etc/systemd/system/vboxguest-defer-load.service >/dev/null
  _chroot chown root:root /etc/systemd/system/vboxguest-defer-load.service
  _chroot chmod 0644 /etc/systemd/system/vboxguest-defer-load.service

  # Enable without depending on systemctl inside chroot
  _chroot ln -sf /etc/systemd/system/vboxguest-defer-load.service \
                /etc/systemd/system/multi-user.target.wants/vboxguest-defer-load.service

  # Breadcrumb to prove inclusion in the running live system
  echo 'ok' | sudo -n tee "$globalVirtFS"/DEFER_MARKER >/dev/null

  # Debug evidence in build log
  # _messagePlain_probe_cmd ls -l "$globalVirtFS"/usr/local/sbin/vboxguest-defer-load.sh
  # _messagePlain_probe_cmd ls -l "$globalVirtFS"/etc/systemd/system/vboxguest-defer-load.service
  # _messagePlain_probe_cmd ls -l "$globalVirtFS"/etc/systemd/system/multi-user.target.wants/vboxguest-defer-load.service
}

# --- inject our installer into the standard live build ---
eval "$(declare -f _live | sed '1s/_live/_live__orig/')"
_live() {
  _messagePlain_nominal "==rmh== Live (modified)"
  _ops_preflight_chroot_clean

  if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"; then _stop 1; fi

  _ops_set_live_user_pw_offline
  _install_vboxguest_defer
  _ops_clear_stale_squashfs


  if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"; then _stop 1; fi
  export safeToDeleteGit="true"; _safeRMR "$scriptLocal"/livefs
}


  # --- append a single deferred GRUB entry (no -lts double-kernel) ---
  eval "$(declare -f _live_grub_here | sed '1s/_live_grub_here/_live_grub_here__orig/')"
  _live_grub_here() {
  _live_grub_here__orig
  cat <<'EOF'

menuentry "Live (VBoxGuest deferred)" {
    linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0 mem=3712M resume=/dev/sda5 modprobe.blacklist=vboxguest vboxguest.defer=1
    initrd /initrd
}
EOF
}



# #############################################################################
# #### Build Failure items ####################################################
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


# Override message functions to reduce multi-threaded mess 
#Cyan. Harmless status messages.
_messagePlain_nominal() {
    local color_start='\E[0;36m'  # Cyan
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}

#Blue. Diagnostic instrumentation.
_messagePlain_probe() {
    local color_start='\E[0;34m'  # Blue
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}

#Blue. Diagnostic instrumentation.
_messagePlain_probe_expr() {
    local color_start='\E[0;34m'  # Blue
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}

#Blue. Diagnostic instrumentation.
_messagePlain_probe_var() {
    local color_start='\E[0;34m'  # Blue
    local color_end='\E[0m'      # Reset
    local var_value=""           # To store the evaluated variable value

    # Check if a variable name is provided
    if [ -n "$1" ]; then
        # Evaluate the variable's value and store it
        eval "var_value=\$$1"
        echo -e "${color_start} $1= ${var_value} ${color_end}"
    else
        echo -e "${color_start} ${color_end}" # Print color without variable if none provided
    fi
    return 0
}

_messageVar() {
    _messagePlain_probe_var "$@"
}


#Green. Working as expected.
_messagePlain_good() {
    local color_start='\E[0;32m'  # Green
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}

#Yellow. May or may not be a problem.
_messagePlain_warn() {
    local color_start='\E[1;33m'  # Yellow (Bold)
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}

#Red. Will result in missing functionality, reduced performance, etc, but not necessarily program failure overall.
_messagePlain_bad() {
    local color_start='\E[0;31m'  # Red
    local color_end='\E[0m'      # Reset
    echo -e "${color_start} $@ ${color_end}"
    return 0
}
