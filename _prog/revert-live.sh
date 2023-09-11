
# Recreates 'vm.img' from booted Live ISO .
# WARNING: May be untested.
# CAUTION: Do NOT introduce external (ie. 'online') dependencies! External dependencies have historically been susceptible to breakage!
_revert-fromLive() {
	# /run/live/rootfs/filesystem.squashfs
    # "$scriptLocal"/vm.img
    
    [[ -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'unexpected: good: found: vm.img' && return 0
    [[ -e "$scriptLocal"/vm-live.iso ]] && _messagePlain_bad 'unexpected: good: found: vm-live.iso' && return 0
    [[ -e "$scriptLocal"/package_rootfs.tar ]] && _messagePlain_bad 'unexpected: good: found: package_rootfs.tar' && return 0

    [[ -e "$scriptLocal"/package_rootfs.tar.flx ]] && _messagePlain_bad 'unexpected: good: found: package_rootfs.tar.flx' && return 0
    
    [[ -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'unexpected: bad: missing: /run/live/rootfs/filesystem.squashfs' && return 0
    
    # /run/live/rootfs/filesystem.squashfs
    

    
    _messageNormal '##### init: _revert-fromLive: create'
	
	
	mkdir -p "$scriptLocal"
	
	_set_ubDistBuild
	
	
	
	_createVMimage "$@"


    _messageNormal 'os: globalVirtFS: write: rootfs'

    ! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	#_mountChRoot_image_x64_prog

    sudo -n rsync -ax --exclude /run/live/rootfs/filesystem.squashfs/vm.img /run/live/rootfs/filesystem.squashfs/package_rootfs.tar /run/live/rootfs/filesystem.squashfs/. "$globalVirtFS"/
    
    _createVMfstab
    #sudo -n mv -f "$globalVirtFS"/fstab-copy "$globalVirtFS"/etc/fstab
    sudo -n rm -f "$globalVirtFS"/fstab-copy

    [[ -d "$globalVirtFS"/boot/efi ]] && mountpoint "$globalVirtFS"/boot/efi >/dev/null 2>&1 && _wait_umount "$globalVirtFS"/boot/efi >/dev/null 2>&1
	[[ -d "$globalVirtFS"/boot ]] && mountpoint "$globalVirtFS"/boot >/dev/null 2>&1 && _wait_umount "$globalVirtFS"/boot >/dev/null 2>&1
	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL


    
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

    sudo -n mv -f "$globalVirtFS"/boot-copy/boot/efi/* "$globalVirtFS"/boot/efi/
	sudo -n mv -f "$globalVirtFS"/boot-copy/boot/efi/.* "$globalVirtFS"/boot/efi/
    sudo -n rmdir "$globalVirtFS"/boot-copy/boot/efi

	sudo -n mv -f "$globalVirtFS"/boot-copy/boot/* "$globalVirtFS"/boot/
    sudo -n mv -f "$globalVirtFS"/boot-copy/boot/.* "$globalVirtFS"/boot/
    sudo -n rmdir "$globalVirtFS"/boot-copy/boot
    sudo -n rmdir "$globalVirtFS"/boot-copy

    ! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL



    _messageNormal 'os: globalVirtFS: write: fs'

    echo "default" | sudo -n tee "$globalVirtFS"/etc/hostname
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/hosts > /dev/null
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	default

CZXWXcRMTo8EmM8i4d









    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)

    _chroot dd if=/dev/zero of=/swapfile bs=1 count=1
	_chroot chmod 0600 /swapfile






    _messageNormal 'chroot: bootloader'
	
	#_nouveau_disable_procedure
	
	# https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting
	#  'NVIDIA driver does not provide an fbdev driver for the high-resolution console for the kernel compiled-in vesafb'
	#   lsmod should show a modsetting driver in use ...
	#echo 'GRUB_CMDLINE_LINUX="nvidia-drm.modeset=1"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	echo 'options nvidia-drm modeset=1' | sudo -n tee "$globalVirtFS"/etc/modprobe.d/nvidia-kms.conf
	
	#echo 'GRUB_CMDLINE_LINUX="nouveau.modeset=0 nvidia-drm.modeset=1"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	
	
	_messagePlain_nominal 'install grub'
	#export getMost_backend="chroot"
	#_set_getMost_backend "$@"
	#_set_getMost_backend_debian "$@"
	#_test_getMost_backend "$@"
	
	#_getMost_backend_aptGetInstall grub-pc-bin
	
	_chroot env DEBIAN_FRONTEND=noninteractive debconf-set-selections <<< "grub-efi-amd64 grub2/update_nvram boolean false"
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y grub-efi grub-efi-amd64
	#_getMost_backend_aptGetInstall linux-image-amd64 linux-headers-amd64 grub-efi
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL


    # Install Hybrid/UEFI bootloader by default. May be rewritten later if appropriate.
	_createVMbootloader-bios
	_createVMbootloader-efi
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	echo 'GRUB_TIMEOUT=1' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	_chroot update-grub
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL



    _chroot_test
}




