#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# 2025.08.11 rmh Address occasional build failures due to missing part file asset
# 2025.08.19 rmh Add VM-specific GRUB option 
# 2025.08.22 rmh Fix setting of user PW, fix build action we broke 

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
