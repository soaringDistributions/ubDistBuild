#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# 2025.08.11 rmh Address occasional build failures due to missing part file asset
# 2025.08.19 rmh Add VM-specific GRUB option 


#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# #############################################################################
# #### GRUB/VBox Defer banner #################################################
_messageNormal '[ops] vboxguest defer: overrides loaded'

# #############################################################################
# #### Offline password (no units; no first-boot anything) ####################
# Use:
#   UB_USER_PW='YourNewPassword!' ./ubiquitous_bash.sh _live
#
# This sets the *live* user's password directly in the rootfs with chpasswd -R.
# If UB_USER_PW is unset or /etc/shadow is not present yet, it’s a no-op.
_ops_set_live_user_pw_offline() {
  if [ -z "${UB_USER_PW:-}" ]; then
    _messageNormal '[ops] live pw: skip (UB_USER_PW not set)'
    return 0
  fi
  if [ ! -e "$globalVirtFS/etc/shadow" ]; then
    _messageNormal "[ops] live pw: skip (/etc/shadow not present yet in $globalVirtFS)"
    return 0
  fi

  _messageNormal '[ops] live pw: setting via chpasswd -R (offline)'
  # set just the 'user' account; uncomment root if you want it too
  printf 'user:%s\n' "$UB_USER_PW" | sudo -n chpasswd -R "$globalVirtFS"
  # printf 'root:%s\n' "$UB_USER_PW" | sudo -n chpasswd -R "$globalVirtFS"

  # breadcrumb (visible inside the VM at /OPS_MARKER_PW)
  echo 'pw:offline:ok' | sudo -n tee "$globalVirtFS/OPS_MARKER_PW" >/dev/null
}

# #############################################################################
# #### Chroot wrapper (quiet; logs only to _openChRoot.debug) #################
eval "$(declare -f _openChRoot | sed '1s/_openChRoot/_openChRoot__orig/')"
_openChRoot() {
  {
    echo "----- $(date -Is) (_openChRoot debug) -----"
    echo "whoami: $(whoami)"
    echo "scriptLocal: $scriptLocal"
    echo "globalVirtFS: $globalVirtFS"
    echo "ubVirtPlatform: $ubVirtPlatform"
    echo "mounts before:"; mount | sed 's/^/  /'; echo
  } >> "$scriptLocal/_openChRoot.debug" 2>&1

  # call the original, but keep any verbosity out of the console
  _openChRoot__orig "$@" >> "$scriptLocal/_openChRoot.debug" 2>&1
  local rc=$?
  echo "rc=${rc}" >> "$scriptLocal/_openChRoot.debug"
  return $rc
}

# #############################################################################
# #### Inter-build cleanup (stale mounts/loops) ###############################
_ops_preflight_chroot_clean() {
  _messageNormal '[ops] preflight: cleanup stale chroot (deep)'

  "$scriptAbsoluteLocation" _closeChRoot --force >/dev/null 2>&1 || true
  "$scriptAbsoluteLocation" _removeChRoot           >/dev/null 2>&1 || true

  # 1) anything under our normal live roots
  awk -v r="$scriptLocal" '$2 ~ "^"r"/v(/|$)" {print length($2),$2}' /proc/mounts |
    sort -nr | awk '{print $2}' |
    while read -r m; do
      sudo umount "$m" 2>/dev/null || sudo umount -l "$m" 2>/dev/null || true
    done

  # 2) loops from this project
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

  # 5) detach loops
  for L in "${_ops_loops[@]}"; do
    sudo losetup -d "$L" 2>/dev/null || true
  done

  # 6) remove stale imagedev breadcrumb
  rm -f "$scriptLocal"/imagedev

  # quick visibility (quiet if nothing to show)
  _messagePlain_probe_cmd 'mount | grep -E "_local/(v/fs|v/.*/fs)|\\.ubtmp/.*/root" || echo "no project mounts"'
  _messagePlain_probe_cmd 'sudo losetup -a | grep "$(pwd)" || echo "no project loop devices"'
}

# #############################################################################
# #### Avoid accidental squashfs appends & home_1 duplication #################
_ops_clear_stale_squashfs() {
  local liveDir="$scriptLocal/livefs/image/live"
  local fs="$liveDir/filesystem.squashfs"
  [ -e "$fs" ] && rm -f "$fs"
  sudo rm -f /root/squashfs_recovery_filesystem.squashfs_* 2>/dev/null || true
}

# A clean copy of the original probe helper (so we can wrap mksquashfs calls)
_messagePlain_probe_cmd_orig() {
  _color_begin_probe
  _safeEcho "$@"
  _color_end
  echo
  if [ $# -eq 1 ]; then
    eval "$1"
  else
    "$@"
  fi
}

# Intercept the final "sudo -n mksquashfs $globalVirtFS ..." and force:
#   -noappend   → stops “Appending to existing …” and prevents home_1
#   -wildcards -e 'home/*' → exclude live /home content duplication
_messagePlain_probe_cmd() {
  if [ "$1" = "sudo" ] && [ "$2" = "-n" ] && [ "$3" = "mksquashfs" ] && [ "$4" = "$globalVirtFS" ]; then
    _messagePlain_probe_cmd_orig "$@" -noappend -wildcards -e 'home/*'
    return $?
  fi
  _messagePlain_probe_cmd_orig "$@"
}

# #############################################################################
# #### VBoxGuest deferral (unchanged behavior) ################################
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

_here_vboxguest_defer_script() {
cat <<'EOF'
#!/bin/sh
set -eu
systemd-detect-virt --quiet --vm || exit 0
grep -qw 'vboxguest.defer=1' /proc/cmdline || exit 0
lsmod | awk '{print $1}' | grep -qx vboxguest && exit 0

i=90
while [ $i -gt 0 ]; do
  pgrep -x plasmashell >/dev/null 2>&1 && break
  pgrep -x startplasma-x11 >/dev/null 2>&1 && break
  sleep 1; i=$((i-1))
done

modprobe -v vboxguest || true
modprobe -v vboxsf    || true
modprobe -v vboxvideo || true
udevadm settle || true
systemctl restart vboxservice 2>/dev/null || true

for uid in $(loginctl list-users --no-legend | awk '{print $1}'); do
  user="$(id -un "$uid" 2>/dev/null || true)"; [ -n "$user" ] || continue
  su -l "$user" -c 'command -v VBoxClient-all >/dev/null && VBoxClient-all >/dev/null 2>&1 || true' || true
done
EOF
}

_install_vboxguest_defer() {
  _messageNormal '[ops] vboxguest defer: installing (late loader)'
  sudo -n mkdir -p "$globalVirtFS"/usr/local/sbin
  sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system
  sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system/multi-user.target.wants

  _here_vboxguest_defer_script  | sudo -n tee "$globalVirtFS"/usr/local/sbin/vboxguest-defer-load.sh >/dev/null
  _chroot chown root:root /usr/local/sbin/vboxguest-defer-load.sh
  _chroot chmod 0755      /usr/local/sbin/vboxguest-defer-load.sh

  _here_vboxguest_defer_service | sudo -n tee "$globalVirtFS"/etc/systemd/system/vboxguest-defer-load.service >/dev/null
  _chroot chown root:root /etc/systemd/system/vboxguest-defer-load.service
  _chroot chmod 0644      /etc/systemd/system/vboxguest-defer-load.service

  _chroot ln -sf /etc/systemd/system/vboxguest-defer-load.service \
                /etc/systemd/system/multi-user.target.wants/vboxguest-defer-load.service

  echo 'ok' | sudo -n tee "$globalVirtFS"/DEFER_MARKER >/dev/null
}

# #############################################################################
# #### Inject into _live() and GRUB entry #####################################
eval "$(declare -f _live | sed '1s/_live/_live__orig/')"
_live() {
  _messagePlain_nominal "==rmh== Live (modified)"
  _ops_preflight_chroot_clean

  if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"; then _stop 1; fi

  _ops_set_live_user_pw_offline      # ← set password directly into rootfs
  _install_vboxguest_defer           # ← add defer unit/script
  _ops_clear_stale_squashfs          # ← ensure fresh squashfs (no append)

  if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"; then _stop 1; fi
  export safeToDeleteGit="true"; _safeRMR "$scriptLocal"/livefs
}

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
# #### Keep your existing reliability helpers (unchanged) #####################
# --- Strict timeout (as in your working version) ---
_timeout_strict() {
  _messagePlain_probe "_timeout_strict → $(printf '%q ' "$@")"
  if command -v timeout >/dev/null 2>&1; then
    _messagePlain_probe "_timeout_strict: coreutils timeout path"
    timeout -k 5 "$@"; local rc=$?
    _messagePlain_probe "_timeout_strict: coreutils rc=$rc"
    return "$rc"
  fi

  _messagePlain_warn "==rmh== **** TEMP _timeout_strict() PATH ***"
  _messagePlain_probe "_timeout_strict: fallback path"
  (
    set +b
    local secs rc krc
    secs="$1"; shift
    _messagePlain_probe "_timeout_strict(fb): secs=$(printf '%q' "$secs") cmd=$(printf '%q ' "$@")"
    "$@" & local cmd=$!
    _messagePlain_probe "_timeout_strict(fb): cmd pid=$cmd"
    (
      sleep "$secs"
      if kill -0 "$cmd" 2>/dev/null; then
        _messageWARN "_timeout_strict(fb): timeout fired → TERM pid $cmd"
        kill -TERM "$cmd" 2>/dev/null
        sleep 3
        if kill -0 "$cmd" 2>/dev/null; then
          _messageWARN "_timeout_strict(fb): escalation → KILL $cmd"
          kill -KILL "$cmd" 2>/dev/null
        fi
        exit 124
      fi
      exit 0
    ) & local killer=$!
    _messagePlain_probe "_timeout_strict(fb): killer pid=$killer"

    wait "$cmd"; rc=$?
    _messagePlain_probe "_timeout_strict(fb): cmd exited rc=$rc"

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
  )
}

# --- gh upload helpers (unchanged from your working copy) ---
_gh_release_asset_present() {
  local currentTag="$1"
  local assetName="$2"
  "$scriptAbsoluteLocation" _timeout_strict 120 \
    gh release view "$currentTag" --json assets 2>/dev/null \
    | grep -F "\"name\":\"$assetName\"" >/dev/null
}

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
      local vtries=0
      while [[ $vtries -lt 5 ]]; do
        if _gh_release_asset_present "$currentTag" "$assetName"; then
          rc=0; break
        fi
        sleep 2; let vtries++
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
    sleep 7; let currentIteration++
  done

  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** upload failed after retries: $assetName → $currentTag"
  fi
  return "$rc"
}

_gh_release_upload_parts-multiple_sequence() {
  _messagePlain_nominal '==rmh== _gh_release_upload_parts: '"$@"
  local currentTag="$1"; shift
  local -a __files=( "$@" )
  local currentStream_max="${UB_GH_UPLOAD_PARALLEL:-12}"
  local currentStreamNum=0

  local currentFile
  for currentFile in "${__files[@]}"; do
    let currentStreamNum++
    "$scriptAbsoluteLocation" _gh_release_upload_part-single_sequence "$currentTag" "$currentFile" &
    eval local currentStream_${currentStreamNum}_PID="$!"
    _messagePlain_probe_var currentStream_${currentStreamNum}_PID

    while [[ $(jobs | wc -l) -ge "$currentStream_max" ]]; do
      echo; jobs; echo
      sleep 2
    done
  done

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
  done
  wait

  local -a expected_names=()
  local f; for f in "${__files[@]}"; do expected_names+=( "$(basename -- "$f")" ); done

  local max_attempts="${UB_GH_VERIFY_ATTEMPTS:-15}"
  local sleep_s="${UB_GH_VERIFY_SLEEP:-8}"
  local assets_json attempt=1
  while :; do
    assets_json=$("$scriptAbsoluteLocation" _timeout_strict 180 gh release view "$currentTag" --json assets 2>/dev/null || true)

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

  local rc=0
  local per_attempts="${UB_GH_VERIFY_PER_ASSET_ATTEMPTS:-6}"
  local per_sleep="${UB_GH_VERIFY_PER_ASSET_SLEEP:-5}"

  local name ok a
  for name in "${expected_names[@]}"; do
    ok=""
    for a in $(seq 1 "$per_attempts"); do
      assets_json=$("$scriptAbsoluteLocation" _timeout_strict 180 gh release view "$currentTag" --json assets 2>/dev/null || true)
      if printf '%s' "$assets_json" | grep -F "\"name\":\"$name\"" >/dev/null; then
        _messagePlain_probe "==rmh== asset verified: $name"; ok="true"; break
      fi
      _messagePlain_probe "==rmh== asset not yet visible ($name), retry ${a}/${per_attempts}"
      sleep "$per_sleep"
    done
    if [[ -z "$ok" ]]; then
      _messageFAIL "==rmh== ** missing asset on release: $name"; rc=1
    fi
  done

  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** some assets were not uploaded successfully"
  else
    _messagePlain_probe "==rmh== all assets verified successfully"
  fi
  return "$rc"
}

# #############################################################################
# #### Message overrides (unchanged from your working copy) ###################
_messagePlain_nominal() { local c='\E[0;36m'; local r='\E[0m'; echo -e "${c} $@ ${r}"; }
_messagePlain_probe()   { local c='\E[0;34m'; local r='\E[0m'; echo -e "${c} $@ ${r}"; }
_messagePlain_probe_expr(){ local c='\E[0;34m'; local r='\E[0m'; echo -e "${c} $@ ${r}"; }
_messagePlain_probe_var(){
  local c='\E[0;34m'; local r='\E[0m'; local v=""; if [ -n "$1" ]; then eval "v=\$$1"; echo -e "${c} $1= ${v} ${r}";
  else echo -e "${c} ${r}"; fi
}
_messageVar(){ _messagePlain_probe_var "$@"; }
_messagePlain_good()   { local c='\E[0;32m';  local r='\E[0m'; echo -e "${c} $@ ${r}"; }
_messagePlain_warn()   { local c='\E[1;33m';  local r='\E[0m'; echo -e "${c} $@ ${r}"; }
_messagePlain_bad()    { local c='\E[0;31m';  local r='\E[0m'; echo -e "${c} $@ ${r}"; }
