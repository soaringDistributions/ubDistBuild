
# Recreates 'vm.img' from booted Live ISO .
# WARNING: May be untested.
# CAUTION: Do NOT introduce external (ie. 'online') dependencies! External dependencies have historically been susceptible to breakage!
#export skimfast=true
#export devfast=true
_revert-fromLive() {
	if [[ "$1" != "" ]]
	then
		#export ubVirtImageIsRootPartition='true'
		export ubVirtImageIsDevice='true'
		export ubVirtImageOverride="$1"
	fi


	# /run/live/rootfs/filesystem.squashfs
    # "$scriptLocal"/vm.img
    
    [[ -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'unexpected: good: found: vm.img' && return 0
    [[ -e "$scriptLocal"/vm-live.iso ]] && _messagePlain_bad 'unexpected: good: found: vm-live.iso' && return 0
    [[ -e "$scriptLocal"/package_rootfs.tar ]] && _messagePlain_bad 'unexpected: good: found: package_rootfs.tar' && return 0

    [[ -e "$scriptLocal"/package_rootfs.tar.flx ]] && _messagePlain_bad 'unexpected: good: found: package_rootfs.tar.flx' && return 0
    
    [[ ! -e /run/live/rootfs/filesystem.squashfs ]] && _messagePlain_bad 'unexpected: bad: missing: /run/live/rootfs/filesystem.squashfs' && return 0
    
    # /run/live/rootfs/filesystem.squashfs
    

    
    _messageNormal '##### init: _revert-fromLive: create'
	
	
	mkdir -p "$scriptLocal"
	
	_set_ubDistBuild
	
	
	#rm -f "$scriptLocal"/l_o
	#rm -f "$scriptLocal"/l_o-chrt
	#rm -f "$scriptLocal"/imagedev
	#rm -f "$scriptLocal"/WARNING
	
	
	_createVMimage


    _messageNormal 'os: globalVirtFS: write: rootfs'

    ! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	#_mountChRoot_image_x64_prog


	if [[ "$FORCE_RSYNC" == "true" ]]
	then
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/root "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/VBoxGuestAdditions "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/opt "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/run "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/srv "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/var "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/opt "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/bin "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/sbin "$globalVirtFS"/
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/etc "$globalVirtFS"/
	
	sudo -n mkdir -p "$globalVirtFS"/usr/lib/modules
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/usr/lib/modules/. "$globalVirtFS"/usr/lib/modules/

	sudo -n mkdir -p "$globalVirtFS"/usr/lib/systemd
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/usr/lib/systemd/. "$globalVirtFS"/usr/lib/systemd/

    sudo -n mkdir -p "$globalVirtFS"/usr/lib
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/usr/lib/. "$globalVirtFS"/usr/lib/

	sudo -n mkdir -p "$globalVirtFS"/usr/bin
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/usr/bin/. "$globalVirtFS"/usr/bin/

	sudo -n mkdir -p "$globalVirtFS"/usr/sbin
    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/usr/sbin/. "$globalVirtFS"/usr/sbin/
    
		    sudo -n rsync -ax --progress --exclude /vm.img --exclude /package_rootfs.tar /run/live/rootfs/filesystem.squashfs/. "$globalVirtFS"/
	else
		sudo -n unsquashfs -f -d "$globalVirtFS" /run/live/medium/live/filesystem.squashfs
	fi




    
    
	# https://unix.stackexchange.com/questions/703887/update-initramfs-is-disabled-live-system-is-running-without-media-mounted-on-r
	_chroot mv -f /usr/sbin/update-initramfs.orig.initramfs-tools /usr/sbin/update-initramfs
    
    
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




	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)


    _messageNormal 'os: globalVirtFS: write: fs'

	local currentHostname
	currentHostname=$(cat "$globalVirtFS"/etc/hostname)

    echo "$currentHostname" | sudo -n tee "$globalVirtFS"/etc/hostname
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/hosts > /dev/null
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	$currentHostname

CZXWXcRMTo8EmM8i4d


	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL






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
	
	#_chroot env DEBIAN_FRONTEND=noninteractive debconf-set-selections <<< "grub-efi-amd64 grub2/update_nvram boolean false"
	#_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y grub-efi grub-efi-amd64
	#_getMost_backend_aptGetInstall linux-image-amd64 linux-headers-amd64 grub-efi
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL


    # Install Hybrid/UEFI bootloader by default. May be rewritten later if appropriate.
	_createVMbootloader-bios
	_createVMbootloader-efi
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	echo 'GRUB_TIMEOUT=1' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	_chroot update-grub
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL



	_messageNormal 'chroot: write: revert: live'

	_write_revert_live

	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

	# https://unix.stackexchange.com/questions/703887/update-initramfs-is-disabled-live-system-is-running-without-media-mounted-on-r
	#_chroot mv -f /usr/sbin/update-initramfs.orig.initramfs-tools /usr/sbin/update-initramfs
	#_chroot /usr/sbin/update-initramfs.orig.initramfs-tools -u -k all
	_chroot /usr/sbin/initramfs-tools -u -k all

	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL


	export nonet="true"
	_chroot_test
}

_revert-fromLive-test() {
	if [[ "$1" != "" ]]
	then
		#export ubVirtImageIsRootPartition='true'
		export ubVirtImageIsDevice='true'
		export ubVirtImageOverride="$1"
	fi
	
	[[ -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'unexpected: good: found: vm.img' && return 0
	[[ -e "$scriptLocal"/vm-live.iso ]] && _messagePlain_bad 'unexpected: good: found: vm-live.iso' && return 0
	
	[[ ! -e /run/live/rootfs/filesystem.squashfs ]] && _messagePlain_bad 'unexpected: bad: missing: /run/live/rootfs/filesystem.squashfs' && return 0
	
	export nonet="true"
	_chroot_test
}


