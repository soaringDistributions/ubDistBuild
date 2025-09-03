#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# 2025.08.11 rmh Address occasional build failures due to missing part file asset
# 2025.08.19 rmh Add VM-specific GRUB option 
# 2025.08.22 rmh Fix setting of user PW, fix build action we broke 

# --- banner so you can see ops.sh got sourced in the build log ---
_messageNormal '[ops] vboxguest defer: overrides loaded'

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

menuentry "Live -lts (VBoxGuest deferred)" {
    linux /vmlinuz-lts boot=live config debug=1 noeject nopersistence selinux=0 modprobe.blacklist=vboxguest vboxguest.defer=1
    initrd /initrd-lts
}
EOF
}

###############################################################################
# Hook into the live ISO build to install defer + set password
###############################################################################
# keep your earlier eval that snapshots the stock _live
eval "$(declare -f _live | sed '1s/_live/_live__orig/')"

_live() {
  _messagePlain_nominal "==rmh== Live (modified)"

  # ensure the playground is clean before opening the chroot
  _ops_preflight_chroot_clean

  # run the stock sequence (opens chroot)
  if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"; then _stop 1; fi

  # our additions while chroot is open
  _install_vboxguest_defer
  _ops_set_pw_offline

  ###########################################################################
  # Guard the final mv inside _live_sequence_out so we never lose the ISO
  ###########################################################################
  _messageNormal '[ops] guard: enabling safe-mv for vm-live.iso'

  # helper: make a unique alt name alongside vm-live.iso
  _ops__vm_live_alt_name() {
    local base="$scriptLocal"/vm-live ts alt i=0
    ts="$(date +%Y%m%d-%H%M%S)"
    alt="${base}_${ts}.iso"
    while [[ -e "$alt" ]]; do
      i=$((i+1))
      alt="${base}_${ts}-${i}.iso"
    done
    printf '%s\n' "$alt"
  }

  # capture the real mv
  _ops__real_mv="$(command -v mv)"

  # temporary wrapper that only intercepts the one mv we care about
  mv() {
    # Only intercept the final live.iso -> vm-live.iso move
    if [[ $# -eq 2 && "$2" == "$scriptLocal"/vm-live.iso && -f "$1" ]]; then
      local src="$1" dst="$2" alt inuse=""
      # best-effort pre-check: is the target file open?
      if command -v lsof >/dev/null 2>&1; then
        lsof -- "$dst" >/dev/null 2>&1 && inuse=1 || inuse=""
      elif command -v fuser >/dev/null 2>&1; then
        fuser -s -- "$dst" && inuse=1 || inuse=""
      fi

      if [[ -n "$inuse" ]]; then
        alt="$(_ops__vm_live_alt_name)"
        _messagePlain_warn "[ops] vm-live.iso appears busy; saving as $(basename "$alt")"
        cp -f -- "$src" "$alt" || return 1
        return 0
      fi

      # try the normal move first; on failure, fall back to alt copy
      if "$_ops__real_mv" -f -- "$src" "$dst" 2> "$safeTmp/.mv_err"; then
        rm -f "$safeTmp/.mv_err" || true
        return 0
      fi

      alt="$(_ops__vm_live_alt_name)"
      _messagePlain_warn "[ops] mv to vm-live.iso failed; saving as $(basename "$alt")"
      if cp -f -- "$src" "$alt"; then
        _messagePlain_warn "[ops] kept new image as $(basename "$alt"); old vm-live.iso left unchanged"
        rm -f "$safeTmp/.mv_err" || true
        return 0
      fi

      _messagePlain_warn "[ops] fallback copy also failed (see $safeTmp/.mv_err if present)"
      return 1
    fi

    # pass-through for every other mv
    command "$_ops__real_mv" "$@"
  }

  # close out normally (with our mv() wrapper active)
  if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"; then
    # tidy wrapper on failure too
    unset -f mv _ops__vm_live_alt_name || true
    unset _ops__real_mv || true
    _stop 1
  fi

  # remove the wrapper so it doesn’t affect anything else
  unset -f mv _ops__vm_live_alt_name || true
  unset _ops__real_mv || true

  # upstream clean-up
  export safeToDeleteGit="true"
  _safeRMR "$scriptLocal"/livefs
}

###############################################################################
# Also catch the ingredient VM image stage and set the password there, too
###############################################################################
if declare -f _create_ingredientVM_image >/dev/null 2>&1; then
  eval "$(declare -f _create_ingredientVM_image | sed '1s/_create_ingredientVM_image/_create_ingredientVM_image__orig/')"
  _create_ingredientVM_image() {
    # let the stock function build the image first
    _create_ingredientVM_image__orig "$@"

    # re-open the chroot, set pw, then close again (best-effort)
    if [ -n "${UB_USER_PW:-}" ]; then
      _messageNormal '[ops] ingredientVM pw: opening chroot and setting password'
      if "$scriptAbsoluteLocation" _openChRoot >/dev/null 2>&1; then
        _ops_set_pw_offline
        "$scriptAbsoluteLocation" _closeChRoot >/dev/null 2>&1 || true
      else
        _messagePlain_warn '[ops] ingredientVM pw: could not open chroot (skipped)'
      fi
    fi
  }
fi
