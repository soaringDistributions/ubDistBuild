##### Core


# WARNING: Defaults for 'ops.sh'. Do NOT expect function overrides to persist if set elsewhere, due to "$scriptAbsoluteLocation" calls, such functions as '_editVBox' and '_editQemu' will ONLY use the function definitions that are always redefined by the script itself.
_set_ubDistBuild() {
	#Enable search if "vm.img" and related files are missing.
	export ubVirtImageLocal="true"
	
	
	###
	
	# ATTENTION: Explicitly override platform. Not all backends support all platforms.
	# chroot , qemu
	# x64-bios , raspbian , x64-efi
	export ubVirtPlatformOverride='x64-efi'
	
	###
	
	
	
	###
	
	# ATTENTION: Override with 'ops' or similar.
	# WARNING: Do not override unnecessarily. Default rules are expected to accommodate typical requirements.
	
	# WARNING: Only applies to imagedev (text) loopback device.
	# x64 bios , raspbian , x64 efi (respectively)
	
	#export ubVirtImagePartition='p1'
	
	#export ubVirtImagePartition='p2'
	
	#export ubVirtImagePartition='p3'
	#export ubVirtImageEFI=p2
	
	
	export ubVirtImageEFI=p1
	export ubVirtImageSwap=p2
	export ubVirtImagePartition=p3
	
	
	# ATTENTION: Unusual 'x64-efi' variation.
	#export ubVirtImagePartition='p2'
	#export ubVirtImageEFI='p1'
	
	###
	
	
	# _vboxGUI() {
	# 	_workaround_VirtualBoxVM "$@"
	# 	
	# 	#VirtualBoxVM "$@"
	# 	#VirtualBox "$@"
	# 	#VBoxSDL "$@"
	# }
	
	
	# _set_instance_vbox_features_app() {
	# 	VBoxManage modifyvm "$sessionid" --usbxhci on
	# 	VBoxManage modifyvm "$sessionid" --rtcuseutc on
	# 	
	# 	VBoxManage modifyvm "$sessionid" --graphicscontroller vmsvga --accelerate2dvideo off --accelerate3d off
	# 	#VBoxManage modifyvm "$sessionid" --graphicscontroller vmsvga --accelerate2dvideo off --accelerate3d on
	# 	
	# 	VBoxManage modifyvm "$sessionid" --paravirtprovider 'default'
	# }
	
	
	# _set_instance_vbox_features_app_post() {
	# 	true
	# 	
	# 	# Optional. Test live ISO image produced by '_live' .
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium "$scriptLocal"/vm-live.iso
	# 	then
	# 		_messagePlain_warn 'fail: vm-live'
	# 	fi
	# 	
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium "$scriptLib"/super_grub2/super_grub2_disk_hybrid_2.04s1.iso
	# 	then
	# 		_messagePlain_warn 'fail: super_grub2'
	# 	fi
	# 	
	# 	# Having attached and then detached the iso image, adds it to the 'media library' and creates the extra disk controller for conveinence, while preventing it from being booted by default.
	# 	# Unfortunately, it seems VirtualBox ignores directives to attempt to boot hard disk before CD image. Possibly due to CD image being a hybrid USB/disk image as well.
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium emptydrive
	# 	then
	# 		_messagePlain_warn 'fail: iso: emptydrive'
	# 	fi
	# }
	
	
	
	
	# # ATTENTION: Override with 'ops' or similar.
	# _integratedQemu_x64_display() {
	# 	
	# 	qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=on)
	# 	
	# 	true
	# }
}
# ATTENTION: NOTICE: Most stuff from 'ops.sh' from kit is here.
type _set_ubDistBuild > /dev/null 2>&1 && _set_ubDistBuild




_create_ubDistBuild-create() {
	_messageNormal '##### init: _create_ubDistBuild-create'
	
	mkdir -p "$scriptLocal"
	
	_set_ubDistBuild
	
	export vmImageFile="$scriptLocal"/vm.img
	[[ -e "$vmImageFile" ]] && _messagePlain_good 'exists: vm.img' && return 0
	[[ -e "$scriptLocal"/vm.img ]] && _messagePlain_good 'exists: vm.img' && return 0
	
	[[ -e "$lock_open" ]]  && _messagePlain_bad 'bad: locked!' && _messageFAIL && _stop 1
	[[ -e "$scriptLocal"/l_o ]]  && _messagePlain_bad 'bad: locked!' && _messageFAIL && _stop 1
	
	! [[ $(df --block-size=1000000000 --output=avail "$scriptLocal" | tr -dc '0-9') -gt "25" ]] && _messageFAIL && _stop 1
	
	
	
	local imagedev
	
	_open
	
	export vmImageFile="$scriptLocal"/vm.img
	[[ -e "$vmImageFile" ]] && _messagePlain_bad 'bad: exists: vm.img' && _messageFAIL && _stop 1
	
	
	_messageNormal 'create: vm.img'
	
	export vmSize=23296
	_createRawImage
	
	
	_messageNormal 'partition: vm.img'
	sudo -n parted --script "$scriptLocal"/vm.img 'mklabel gpt'
	
	# Unusual.
	#   EFI, Image/Root.
	# Former default, only preferable if disk is strictly spinning CAV and many more bits per second with beginning tracks.
	#   Swap, EFI, Image/Root.
	# Compromise. May have better compatibility, may reduce CLV (and zoned CAV) speed changes from slowest tracks at beginning of some optical discs.
	#   EFI, Swap, Image/Root.
	# Expect <8MiB usage of EFI parition FAT32 filesystem, ~28GiB usage of Image/Root partition ext4 filesystem.
	# 512MiB EFI, 5120MiB Swap, remainder Image/Root
	
	# CAUTION: Must match _set_ubDistBuild .
	#export ubVirtImageEFI=p?
	#export ubVirtImageSwap=p?
	#export ubVirtImagePartition=p?
	
	
	
	# ATTENTION: NOTICE: Larger EFI partition may be more compatible. Larger Swap partition may be more useful for hibernation.
	
	#sudo -n parted --script "$scriptLocal"/vm.img 'mkpart EFI fat32 '"1"'MiB '"513"'MiB'
	sudo -n parted --script "$scriptLocal"/vm.img 'mkpart EFI fat32 '"1"'MiB '"73"'MiB'
	
	sudo -n parted --script "$scriptLocal"/vm.img 'set 1 msftdata on'
	sudo -n parted --script "$scriptLocal"/vm.img 'set 1 boot on'
	sudo -n parted --script "$scriptLocal"/vm.img 'set 1 esp on'
	
	#sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"513"'MiB '"5633"'MiB'
	#sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"513"'MiB '"3073"'MiB'
	sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"73"'MiB '"97"'MiB'
	
	#sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"5633"'MiB '"23295"'MiB'
	#sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"3073"'MiB '"23295"'MiB'
	sudo -n parted --script "$scriptLocal"/vm.img 'mkpart primary '"97"'MiB '"23295"'MiB'
	
	
	sudo -n parted --script "$scriptLocal"/vm.img 'unit MiB print'
	
	
	_close
	
	
	
	
	# Format partitions .
	_messageNormal 'format: vm.img'
	#"$scriptAbsoluteLocation" _loopImage_sequence || _stop 1
	! "$scriptAbsoluteLocation" _openLoop && _messagePlain_bad 'fail: _openLoop' && _messageFAIL
	
	mkdir -p "$globalVirtFS"
	"$scriptAbsoluteLocation" _checkForMounts "$globalVirtFS" && _messagePlain_bad 'bad: mounted: globalVirtFS' && _messageFAIL && _stop 1
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	local imagepart
	local loopdevfs
	
	# Compression from btrfs may free up ~8GB . Some performance degradation may result if files with many random writes (eg. COW VM images) are used with btrfs .
	# https://www.phoronix.com/scan.php?page=article&item=btrfs-zstd-compress&num=4
	# https://btrfs.wiki.kernel.org/index.php/Compression
	# https://unix.stackexchange.com/questions/394973/why-would-i-want-to-disable-copy-on-write-while-creating-qemu-images
	# https://gist.github.com/niflostancu/03810a8167edc533b1712551d4f90a14
	
	
	imagepart="$imagedev""$ubVirtImageEFI"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkfs.vfat -F 32 -n EFI "$imagepart" || _stop 1
	
	imagepart="$imagedev""$ubVirtImagePartition"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	#sudo -n mkfs.ext4 -e remount-ro -E lazy_itable_init=0,lazy_journal_init=0 -m 0 "$imagepart" || _stop 1
	sudo -n mkfs.btrfs --checksum xxhash -M -d single "$imagepart" || _stop 1
	
	imagepart="$imagedev""$ubVirtImageSwap"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkswap "$imagepart" || _stop 1
	
	#"$scriptAbsoluteLocation" _umountImage || _stop 1
	! "$scriptAbsoluteLocation" _closeLoop && _messagePlain_bad 'fail: _closeLoop' && _messageFAIL
	
	
	
	
	
	_messageNormal 'os: globalVirtFS: debootstrap'
	
	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	# https://gist.github.com/superboum/1c7adcd967d3e15dfbd30d04b9ae6144
	# https://gist.github.com/dyejon/8e78b97c4eba954ddbda7ae482821879
	#http://deb.debian.org/debian/
	#--components=main --include=inetutils-ping,iproute
	! sudo -n debootstrap --variant=minbase --arch amd64 bullseye "$globalVirtFS" && _messageFAIL
	
	
	
	_messageNormal 'os: globalVirtFS: write: fs'
	
	
	sudo -n mkdir -p "$globalVirtFS"/media/bootdisc
	sudo -n chmod 755 "$globalVirtFS"/media/bootdisc
	
	
	# https://gist.github.com/varqox/42e213b6b2dde2b636ef#edit-fstab-file
	
	local ubVirtImagePartition_UUID
	ubVirtImagePartition_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImagePartition" | tr -dc 'a-zA-Z0-9\-')
	
	#echo 'UUID='"$ubVirtImagePartition_UUID"' / ext4 errors=remount-ro 0 1' | sudo -n tee "$globalVirtFS"/etc/fstab
	echo 'UUID='"$ubVirtImagePartition_UUID"' / btrfs defaults,compress=zstd:1 0 1' | sudo -n tee "$globalVirtFS"/etc/fstab
	
	
	# initramfs-update, from chroot, may not enable hibernation/resume... may be device specific
	
	local ubVirtImageSwap_UUID
	ubVirtImageSwap_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImageSwap" | tr -dc 'a-zA-Z0-9\-')
	
	echo '#UUID='"$ubVirtImageSwap_UUID"' swap swap defaults 0 0' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	
	
	local ubVirtImageEFI_UUID
	ubVirtImageEFI_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImageEFI" | tr -dc 'a-zA-Z0-9\-')
	
	echo 'UUID='"$ubVirtImageEFI_UUID"' /boot/efi vfat umask=0077 0 1' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	
	if ! sudo -n cat "$globalVirtFS"/etc/fstab | grep 'uk4uPhB663kVcygT0q' | grep 'bootdisc' > /dev/null 2>&1
	then
		echo 'LABEL=uk4uPhB663kVcygT0q /media/bootdisc iso9660 ro,nofail 0 0' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	fi
	
	
	
	echo "default" | sudo -n tee "$globalVirtFS"/etc/hostname
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/hosts > /dev/null
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	default

CZXWXcRMTo8EmM8i4d
	
	
	sudo -n mkdir -p "$globalVirtFS"/etc/sddm.conf.d
	
	echo '[Autologin]
User=user
Session=plasma
Relogin=true
' | sudo -n tee "$globalVirtFS"/etc/sddm.conf.d/autologin.conf
	
	
	
	
	sudo -n mkdir -p "$globalVirtFS"/root
	sudo -n cp -f "$scriptLib"/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/
	sudo -n chmod 755 "$globalVirtFS"/root/_get_nvidia.sh
	
	
	
	
	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL
	
	
	
	
	
	
	_messageNormal 'chroot: config'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	_chroot dd if=/dev/zero of=/swapfile bs=1 count=1
	#_chroot dd if=/dev/zero of=/swapfile bs=1M count=1536
	_chroot chmod 0600 /swapfile
	#_chroot mkswap /swapfile
	#_chroot swapon /swapfile
	#_chroot echo '/swapfile swap swap defaults 0 0' | _chroot tee -a /etc/fstab
	
	
	
	# https://gist.github.com/varqox/42e213b6b2dde2b636ef#install-firmware
	
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	
	_getMost_backend apt-get update
	
	
	_messagePlain_nominal 'ca-certificates, repositories, mirrors, tasksel standard, hostnamectl'
	_getMost_backend_aptGetInstall ca-certificates
	
	
	
	
	
	# https://askubuntu.com/questions/135339/assign-highest-priority-to-my-local-repository
	#  'There is no way to assign highest priority to local repository without using sources.list file. you must put them in top of "sources.list" if you want to assign highest priority to your local repo.'
	sudo -n mv "$globalVirtFS"/etc/apt/sources.list "$globalVirtFS"/etc/apt/sources.list.upstream
	sudo -n rm -f "$globalVirtFS"/etc/apt/sources.list
	
	# https://wiki.debian.org/Cloud/MicrosoftAzure
	# http://azure.archive.ubuntu.com/ubuntu
	#  From ubuntu.com . Apparently used by Github Actions, but apparently not a fast internal Azure mirror.
	# http://debian-archive.trafficmanager.net/debian
	#  Apparently responds to external (from outside Azure) wget .
	#[[ "$CI" != "" ]]
	
	# https://docs.hetzner.com/robot/dedicated-server/operating-systems/hetzner-aptitude-mirror/
	# ATTENTION: Disabled by default (ie. 'if false').
	if false && wget -qO- --dns-timeout=15 --connect-timeout=15 --read-timeout=15 --timeout=15 https://mirror.hetzner.com > /dev/null
	then
		cat << CZXWXcRMTo8EmM8i4d | sudo -n tee -a "$globalVirtFS"/etc/apt/sources.list > /dev/null
deb https://mirror.hetzner.com/debian/packages  bullseye           main contrib non-free
deb https://mirror.hetzner.com/debian/packages  bullseye-updates   main contrib non-free
deb https://mirror.hetzner.com/debian/security  bullseye-security  main contrib non-free
deb https://mirror.hetzner.com/debian/packages  bullseye-backports main contrib non-free



CZXWXcRMTo8EmM8i4d
	fi
	
	
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee -a "$globalVirtFS"/etc/apt/sources.list > /dev/null
deb https://deb.debian.org/debian/ bullseye main contrib non-free
deb-src https://deb.debian.org/debian/ bullseye main contrib non-free

deb https://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src https://security.debian.org/debian-security bullseye-security main contrib non-free

deb https://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src https://deb.debian.org/debian/ bullseye-updates main contrib non-free

deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free



CZXWXcRMTo8EmM8i4d
	
	_getMost_backend apt-get update
	
	
	_messagePlain_nominal 'ca-certificates'
	_getMost_backend_aptGetInstall ca-certificates
	
	
	
	# ATTENTION: WARNING: tasksel
	_chroot tasksel install standard
	
	
	_getMost_backend_aptGetInstall hostnamectl
	_chroot hostnamectl set-hostname default
	
	
	
	_getMost_backend_aptGetInstall btrfs-tools
	_getMost_backend_aptGetInstall btrfs-progs
	_getMost_backend_aptGetInstall btrfs-compsize
	_getMost_backend_aptGetInstall zstd
	
	_getMost_backend_aptGetInstall libwxgtk3.0-gtk3-0v5
	
	
	
	
	_messagePlain_nominal 'firmware-linux'
	_getMost_backend_aptGetInstall firmware-linux
	_getMost_backend_aptGetInstall firmware-linux-free
	_getMost_backend_aptGetInstall firmware-linux-nonfree
	_getMost_backend_aptGetInstall firmware-misc-nonfree
	
	_getMost_backend_aptGetInstall firmware-iwlwifi
	_getMost_backend_aptGetInstall firmware-realtek
	_getMost_backend_aptGetInstall firmware-ralink
	_getMost_backend_aptGetInstall firmware-qcom-media
	_getMost_backend_aptGetInstall firmware-qcom-soc
	_getMost_backend_aptGetInstall firmware-ti-connectivity
	_getMost_backend_aptGetInstall firmware-amd-graphics
	_getMost_backend_aptGetInstall firmware-myricom
	_getMost_backend_aptGetInstall firmware-ath9k-htc
	_getMost_backend_aptGetInstall firmware-samsung
	_getMost_backend_aptGetInstall firmware-atheros
	_getMost_backend_aptGetInstall firmware-libertas
	_getMost_backend_aptGetInstall firmware-netxen
	_getMost_backend_aptGetInstall firmware-intelwimax
	_getMost_backend_aptGetInstall firmware-brcm80211
	_getMost_backend_aptGetInstall firmware-intel-sound
	_getMost_backend_aptGetInstall firmware-cavium
	_getMost_backend_aptGetInstall firmware-b43legacy-installer
	_getMost_backend_aptGetInstall firmware-qlogic
	_getMost_backend_aptGetInstall firmware-adi
	_getMost_backend_aptGetInstall firmware-tomu
	_getMost_backend_aptGetInstall firmware-zd1211
	_getMost_backend_aptGetInstall firmware-crystalhd
	_getMost_backend_aptGetInstall firmware-netronome
	_getMost_backend_aptGetInstall firmware-b43-installer
	_getMost_backend_aptGetInstall firmware-bnx2x
	_getMost_backend_aptGetInstall firmware-ath9k-htc-dbgsym
	_getMost_backend_aptGetInstall firmware-b43-lpphy-installer
	_getMost_backend_aptGetInstall firmware-bnx2
	_getMost_backend_aptGetInstall firmware-siano
	_getMost_backend_aptGetInstall firmware-sof-signed
	
	_getMost_backend_aptGetInstall bladerf-firmware-fx3
	_getMost_backend_aptGetInstall bluez-firmware
	_getMost_backend_aptGetInstall atmel-firmware
	
	
	_getMost_backend_aptGetInstall firmware-ipw2x00
	_chroot sh -c 'echo "debconf firmware-ipw2x00/license/accepted select true" | debconf-set-selections'
	# https://github.com/unman/notes/blob/master/apt_automation
	
	# ATTENTION: Obviously, broadcast TV is not a 'bootstrapping' prerequsite, this can be easily removed from default if necessary.
	_chroot sh -c 'echo "debconf firmware-ivtv/license/accepted select true" | debconf-set-selections'
	_getMost_backend_aptGetInstall firmware-ivtv
	
	
	sudo -n cp "$scriptLib"/setup/debian/firmware-realtek_20210818-1_all.deb "$globalVirtFS"/
	if _chroot ls -A -1 /firmware-realtek_20210818-1_all.deb > /dev/null
	then
		_chroot dpkg -i /firmware-realtek_20210818-1_all.deb
	else
		_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-realtek_20210818-1_all.deb
		_chroot dpkg -i ./firmware-realtek_20210818-1_all.deb
	fi
	
	
	
	
	_messagePlain_nominal 'tzdata, locales'
	_getMost_backend_aptGetInstall tzdata
	_getMost_backend_aptGetInstall locales
	
	_messagePlain_nominal 'timedatectl, update-locale, localectl'
	_chroot timedatectl set-timezone US/Eastern
	_chroot update-locale LANG=en_US.UTF-8 LANGUAGE
	_chroot localectl set-locale LANG=en_US.UTF-8
	_chroot localectl --no-convert set-x11-keymap us pc104
	
	
	
	
	
	_messageNormal 'chroot: _getMost'
	
	export getMost_backend="chroot"
	_getMost_debian11
	
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade
	
	
	
	_messageNormal 'chroot: bootloader'
	
	
	#imagedev=$(cat "$scriptLocal"/imagedev)
	
	#export ubVirtImageEFI=p1
	#export ubVirtImageSwap=p2
	#export ubVirtImagePartition=p3
	
	_messagePlain_nominal 'install grub'
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	
	_chroot env DEBIAN_FRONTEND=noninteractive debconf-set-selections <<< "grub-efi-amd64 grub2/update_nvram boolean false"
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y grub-efi grub-efi-amd64
	_getMost_backend_aptGetInstall linux-image-amd64 linux-headers-amd64 grub-efi
	
	
	_messagePlain_nominal 'grub-install'
	
	# https://unix.stackexchange.com/questions/273329/can-i-install-grub2-on-a-flash-drive-to-boot-both-bios-and-uefi
	#  'precondition for this to work is that you use GPT partitioning and that you have an BIOS boot partition (1 MiB is enough).'
	#_chroot grub2-install --modules=part_msdos --target=i386-pc "$imagedev"

	
	_messagePlain_probe_cmd _chroot grub-install --boot-directory=/boot --root-directory=/ --modules=part_msdos --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck --no-nvram --removable "$imagedev"
	_messagePlain_probe_cmd _chroot grub-install --boot-directory=/boot --root-directory=/ --modules=part_msdos --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck --no-nvram --removable "$imagedev""$ubVirtImageEFI"
	
	_messagePlain_probe_cmd _chroot grub-install --boot-directory=/boot --root-directory=/ --modules=part_msdos --target=x86_64-efi --efi-directory=/boot/efi --recheck "$imagedev"
	
	#sudo -n mkdir -p "$globalVirtFS"/boot/efi/EFI/BOOT/
	#sudo -n cp "$globalVirtFS"/boot/efi/EFI/debian/grubx64.efi "$globalVirtFS"/boot/efi/EFI/BOOT/bootx64.efi
	
	# https://linuxconfig.org/how-to-disable-blacklist-nouveau-nvidia-driver-on-ubuntu-20-04-focal-fossa-linux
	# https://askubuntu.com/questions/747314/is-nomodeset-still-required
	#echo 'GRUB_CMDLINE_LINUX="nouveau.modeset=0"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	echo 'blacklist nouveau' | sudo -n tee "$globalVirtFS"/etc/modprobe.d/blacklist-nvidia-nouveau.conf
	echo 'options nouveau modeset=0' | sudo -n tee -a "$globalVirtFS"/etc/modprobe.d/blacklist-nvidia-nouveau.conf
	
	
	
	
	_messagePlain_nominal 'update-grub'
	_chroot update-grub
	
	_messagePlain_nominal 'update-initramfs'
	_chroot update-initramfs -u
	
	
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}
_create_ubDistBuild-rotten_install() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	sudo -n cp -f "$scriptAbsoluteLocation" "$globalVirtFS"/ubiquitous_bash.sh
	[[ ! -e "$globalVirtFS"/ubiquitous_bash.sh ]] && _messageFAIL
	sudo -n chmod 755 "$globalVirtFS"/ubiquitous_bash.sh
	
	
	
	! _chroot /rotten_install.sh _custom_kernel && _messageFAIL
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _install && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade
	
	
	_chroot apt-get -y clean
	_chroot sudo apt-get autoremove --purge
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# WARNING: No production use.
_create_ubDistBuild-rotten_install-bootOnce() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: bootOnce'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _custom_bootOnce && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}
# WARNING: No production use.
_create_ubDistBuild-rotten_install-kde() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: kde'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _custom_kde_drop && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}


_create_ubDistBuild-rotten_install-core() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: core'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	if [[ -e "$scriptLocal"/core.tar.xz ]]
	then
		[[ ! -e "$scriptLocal"/core.tar.xz ]] && _messageFAIL
		#sudo -n cp -f "$scriptLocal"/core.tar.xz "$globalVirtFS"/core.tar.xz
		#[[ ! -e "$globalVirtFS"/core.tar.xz ]] && _messageFAIL
		#sudo -n chmod 644 "$globalVirtFS"/core.tar.xz
		
		
		tar -xvf "$scriptLocal"/core.tar.xz -C "$globalVirtFS"/home/user/
		_chroot chown -R user:user /home/user/core
	fi
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _custom_core_drop && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}


_create_ubDistBuild-bootOnce-qemu_sequence() {
	! type qemu-system-x86_64 > /dev/null 2>&1 && _stop 1
	
	export qemuHeadless="true"
	
	local currentPID
	local currentPID_qemu
	local currentNumProc
	
	"$scriptAbsoluteLocation" _zSpecial_qemu "$@" &
	currentPID="$!"
	sleep 6
	currentPID_qemu=$(ps -ef --sort=start_time | grep qemu | grep -v grep | tr -dc '0-9 \n' | tail -n1 | sed 's/\ *//' | cut -f1 -d\  )
	
	
	##disown -h $currentPID
	#disown -a -h -r
	#disown -a -r
	
	# Up to 700s per kernel (ie. modules), plus 500s, total of 1147s for one kernel, 1749s to wait for three kernels.
	_messagePlain_nominal 'wait: 2800s'
	local currentIterationWait
	currentIterationWait=0
	pgrep qemu-system
	pgrep qemu
	ps -p "$currentPID"
	while [[ "$currentIterationWait" -lt 2800 ]] && ( pgrep qemu-system > /dev/null 2>&1 || pgrep qemu > /dev/null 2>&1 || ps -p "$currentPID" > /dev/null 2>&1 )
	do
		sleep 1
		let currentIterationWait=currentIterationWait+1
	done
	_messagePlain_probe_var currentIterationWait
	[[ "$currentIterationWait" -ge 2800 ]] && _messagePlain_bad 'bad: fail: bootdisc: poweroff'
	sleep 27
	
	
	# May not be necessary. Theoretically redundant.
	local currentStopJobs
	currentStopJobs=$(jobs -p -r 2> /dev/null)
	_messagePlain_probe_var currentStopJobs
	[[ "$currentStopJobs" != "" ]] && kill "$currentStopJobs"
	
	#disown -h $currentPID
	disown -a -h -r
	disown -a -r
	
	
	currentNumProc=$(ps -e | grep qemu-system-x86 | wc -l | tr -dc '0-9')
	_messagePlain_probe_var currentNumProc
	_messagePlain_probe '$$= '$$
	_messagePlain_probe_var currentPID
	kill "$currentPID"
	_messagePlain_probe_var currentPID_qemu
	kill "$currentPID_qemu"
	sleep 1
	
	if [[ "$currentNumProc" == "1" ]]
	then
		pkill qemu-system-x86
		sleep 3
		pkill -KILL qemu-system-x86
		sleep 3
	fi
	
	echo
	return 0
}
_create_ubDistBuild-bootOnce-fsck_sequence() {
	_messagePlain_nominal 'fsck'
	
	_set_ubDistBuild
	
	! "$scriptAbsoluteLocation" _openLoop && _messagePlain_bad 'fail: _openLoop' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	_messagePlain_probe sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	[[ "$?" != "0" ]] && _messageFAIL
	
	#_messagePlain_probe sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	#sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	#sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	_messagePlain_probe sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	[[ "$?" != "0" ]] && _messageFAIL
	
	! "$scriptAbsoluteLocation" _closeLoop && _messagePlain_bad 'fail: _closeLoop' && _messageFAIL
	return 0
}
_create_ubDistBuild-bootOnce() {
	_messageNormal '##### init: _create_ubDistBuild-bootOnce'
	
	
	_messageNormal 'chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# WARNING: Do NOT use twice. Usually already effectively called by '_create_ubDistBuild-rotten_install' .
	#_create_ubDistBuild-rotten_install-bootOnce
	
	
	## ATTENTION: NOTICE: Resets any changes to crontab (ie. by rotten_install ).
	##echo | _chroot crontab '-'
	##echo | sudo -n -u user bash -c "crontab -"
	##echo '@reboot cd '/home/user'/ ; '/home/user'/rottenScript.sh _run' | sudo -n -u user bash -c "crontab -"
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/.config/autostart
	##_here_bootdisc_statup_xdg | sudo -n tee "$globalVirtFS"/home/user/.config/autostart/startup.desktop > /dev/null
	##_chroot chown -R user:user /home/user/.config
	##_chroot chmod 555 /home/user/.config/autostart/startup.desktop
	
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/___quick
	##echo 'sudo -n mount -t fuse.vmhgfs-fuse -o allow_other,uid=$(id -u "$USER"),gid=$(id -g "$USER") .host: "$HOME"/___quick' | sudo -n tee "$globalVirtFS"/home/user/___quick/mount.sh
	##_chroot chown -R user:user /home/user/___quick
	##_chroot chmod 755 /home/user/___quick/mount.sh
	
	##( _chroot crontab -l ; echo '@reboot /media/bootdisc/rootnix.sh > /var/log/rootnix.log 2>&1' ) | _chroot crontab '-'
	
	##( _chroot sudo -n -u user bash -c "crontab -l" ; echo '@reboot cd /home/'"$custom_user"'/.ubcore/ubiquitous_bash/lean.sh _unix_renice_execDaemon' ) | _chroot sudo -n -u user bash -c "crontab -"
	
	_chroot /sbin/vboxconfig
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	
	
	
	_messageNormal 'qemu'
	
	local currentIteration
	
	for currentIteration in $(seq 1 3)
	do
		_messagePlain_probe_var currentIteration
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-qemu_sequence "$@"
		then
			_messageFAIL
		fi
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-fsck_sequence "$@"
		then
			_messageFAIL
		fi
	done
	
	
	_messageNormal '##### _create_ubDistBuild-bootOnce: chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# https://stackoverflow.com/questions/8579330/appending-to-crontab-with-a-shell-script-on-ubuntu
	
	( _chroot crontab -l ; echo '@reboot /root/_get_nvidia.sh _autoinstall > /var/log/_get_nvidia.log 2>&1' ) | _chroot crontab '-'
	
	
	
	_chroot dpkg -l | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
	
	echo | sudo -n tee "$globalVirtFS"/regenerate > /dev/null
	
	
	# WARNING: Important. May drastically reduce image size, especially if large temporary files (ie. apt cache) have been used. *Very* compressible zeros.
	_chroot rm -f /fill > /dev/null 2>&1
	_chroot dd if=/dev/zero of=/fill bs=1M count=1 oflag=append conv=notrunc status=progress
	_chroot btrfs property set /fill compression ""
	_chroot dd if=/dev/zero of=/fill bs=1M oflag=append conv=notrunc status=progress
	_chroot rm -f /fill
	
	# Run only once. If used two or more times, apparently may decrease available storage by ~1GB .
	# Apparently, if defrag is run once with compression, rootfs usage may reduce from ~6.6GB to ~5.9GB . However, running again may expand usage back to ~6.6GB.
	# https://github.com/kdave/btrfs-progs/issues/184
	_chroot btrfs filesystem defrag -r -czstd /
	
	_chroot df -h /
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	return 0
}


_create_ubDistBuild() {
	if ! _create_ubDistBuild-create "$@"
	then
		_messageFAIL
	fi
	if ! _create_ubDistBuild-rotten_install "$@"
	then
		_messageFAIL
	fi
	if ! _create_ubDistBuild-bootOnce "$@"
	then
		_messageFAIL
	fi
	
	if ! _create_ubDistBuild-rotten_install-core "$@"
	then
		_messageFAIL
	fi
	
	return 0
}




_custom_ubDistBuild() {
	# TODO: _setup for all infrastructure/installations
		# _custom_core from rotten_install  ?  probably not ... these are tests which rotten_install may not normally run
	
	# TODO: live, live-more, etc
	
	true
}



_package_ubDistBuild_image() {
	cd "$scriptLocal"
	
	! [[ -e "$scriptLocal"/ops.sh ]] && echo >> "$scriptLocal"/ops.sh
	
	rm -f "$scriptLocal"/package_image.tar.xz > /dev/null 2>&1
	
	# https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/
	# https://stephane.lesimple.fr/blog/lzop-vs-compress-vs-gzip-vs-bzip2-vs-lzma-vs-lzma2xz-benchmark-reloaded/
	env XZ_OPT="-2 -T0" tar -cJvf "$scriptLocal"/package_image.tar.xz ./vm.img ./ops.sh
	
	! [[ -e "$scriptLocal"/package_image.tar.xz ]] && _messageFAIL
	
	return 0
}



_upload_ubDistBuild_image() {
	_package_ubDistBuild_image "$@"
	cd "$scriptLocal"
	
	! [[ -e "$scriptLocal"/package_image.tar.xz ]] && _messageFAIL
	
	_rclone_limited --progress copy "$scriptLocal"/package_image.tar.xz distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messageFAIL
	
	if ls -A -1 "$scriptLocal"/*.log
	then
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-create.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-rotten_install.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-bootOnce.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_upload_ubDistBuild_image.log distLLC_build_ubDistBuild:
	fi
	return 0
}

_upload_ubDistBuild_custom() {
	cd "$scriptLocal"
	
	#package_custom.tar.xz
	# TODO
	
	true
}



_croc_ubDistBuild_image_out_message() {
	sleep 3
	while pgrep '^croc$' || ps -p "$currentPID"
	#while true
	do
		[[ -e "$scriptLocal"/croc.log ]] && tail "$scriptLocal"/croc.log
		sleep 3
	done
}

_croc_ubDistBuild_image_out() {
	_mustHaveCroc
	cd "$scriptLocal"
	
	! [[ -e "$scriptLocal"/package_image.tar.xz ]] && _messageFAIL
	
	
	local currentPID
	
	"$scriptAbsoluteLocation" _croc_ubDistBuild_image_out_message &
	
	currentPID="$!"
	
	
	croc send "$scriptLocal"/package_image.tar.xz 2>&1 | tee "$scriptLocal"/croc.log
	
	
	
	
	
	kill "$currentPID"
	sleep 3
	kill -KILL "$currentPID"
	
	return 0
}

_croc_ubDistBuild_image() {
	_mustHaveCroc
	
	_package_ubDistBuild_image "$@"
	
	_croc_ubDistBuild_image_out "$@"
}



# ATTENTION: Override with 'ops.sh' or similar.
_zSpecial_qemu_sequence() {
	_messagePlain_nominal 'init: _zSpecial_qemu'
	_start
	
	
	if [[ "$qemuHeadless" == "true" ]]
	then
		#_commandBootdisc
		
		! _prepareBootdisc && _messageFAIL
		
		cp "$scriptAbsoluteLocation" "$hostToGuestFiles"/
		"$scriptBin"/.ubrgbin.sh _ubrgbin_cpA "$scriptBin" "$hostToGuestFiles"/_bin
		
		
		# A rather complicated issue with VirtualBox vboxdrv kernel module.
		# Module vboxdrv build may be attempted for running kernel of ChRoot host.
		# Sevice vboxdrv will attempt to build, may timeout in ~5 minutes (due to slow qemu without kvm), fail, every boot.
		# Since this should not take much time or power for modern CPUs, and should only affect the ability run VirtualBox guests on first boot (ie. does not affect guest additions), this is expected at most a minor inconvenience.
		
		# sudo -n systemctl status vboxdrv
		echo '#!/usr/bin/env bash' >> "$hostToGuestFiles"/cmd.sh
		echo 'sudo -n update-grub' >> "$hostToGuestFiles"/cmd.sh
		echo '_detect_process_compile() {
	pgrep cc1 && return 0
	pgrep apt && return 0
	pgrep dpkg && return 0
	top -b -n1 | tail -n+8 | head -n1 | grep packagekit && return 0
	sudo -n systemctl status vboxdrv | grep loading && return 0
	return 1
} ' >> "$hostToGuestFiles"/cmd.sh
		
		# Commenting this may reduce first iteration 'currentIterationWait' by ~120s , possibly improving opportunity to successfully compile through slow qemu without kvm.
		# If uncommented, any indefinite delay in '_detect_process_compile' may cause failure.
		#echo 'while _detect_process_compile && sleep 27 && _detect_process_compile && sleep 27 && _detect_process_compile ; do sleep 27 ; done' >> "$hostToGuestFiles"/cmd.sh
		
		echo 'sleep 15' >> "$hostToGuestFiles"/cmd.sh
		echo '! sudo -n lsmod | grep -i vboxdrv && sudo -n /sbin/vboxconfig' >> "$hostToGuestFiles"/cmd.sh
		echo 'sleep 75' >> "$hostToGuestFiles"/cmd.sh
		echo 'sudo -n poweroff' >> "$hostToGuestFiles"/cmd.sh
		
		! _writeBootdisc && _messageFAIL
	fi
	
	
	
	[[ "$qemuHeadless" == "true" ]] && qemuArgs+=(-nographic)
	
	
	qemuArgs+=(-usb)
	
	# *nested* x64 hardware vt
	#qemuArgs+=(-cpu host)
	
	# CPU >2 may force more compatible SMP kernel, etc.
	qemuArgs+=(-smp 2)
	
	
	
	
	# vm.img
	qemuUserArgs+=(-drive format=raw,file="$scriptLocal"/vm.img)
	
	# LiveCD
	#qemuUserArgs+=(-drive file="$ub_override_qemu_livecd",media=cdrom)
	
	# LiveUSB, hibernate/bup, etc
	#qemuUserArgs+=(-drive format=raw,file="$ub_override_qemu_livecd_more")
	
	# Installation CD image.
	#qemuUserArgs+=(-drive file="$scriptLocal"/netinst.iso,media=cdrom -boot c)
	
	
	
	
	[[ -e "$hostToGuestISO" ]] && qemuUserArgs+=(-drive file="$hostToGuestISO",media=cdrom)
	
	# Boot from whichever emulated disk connected ('-boot c' for emulated disc 'cdrom')
	qemuUserArgs+=(-boot d)
	
	
	
	
	# Must have at least 4096MB for 'livecd' , unless even larger memory allocation has been configured .
	# Must have >=8704MB for MSW10 or MSW11 . GNU/Linux may eventually follow with similar expectations.
	# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
	#  '7 GB of RAM memory'
	#  '14 GB of SSD disk space'
	#qemuUserArgs+=(-m "8704")
	#qemuUserArgs+=(-m "3072")
	qemuUserArgs+=(-m "1664")
	
	
	[[ "$qemuUserArgs_netRestrict" == "" ]] && qemuUserArgs_netRestrict="n"
	qemuUserArgs+=(-net nic,model=rtl8139 -net user,restrict="$qemuUserArgs_netRestrict")
	#,smb="$sharedHostProjectDir"
	
	
	qemuArgs+=(-device usb-tablet)
	
	
	#qemuArgs+=(-device ich9-intel-hda -device hda-duplex)
	
	qemuArgs+=(-show-cursor)
	
	
	
	#qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=off)
	##qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=on)
	
	qemuArgs+=(-device qxl-vga)
	
	#qemuArgs+=(-vga cirrus)
	
	#qemuArgs+=(-vga std)
	
	
	
	# hardware vt
	if _testQEMU_hostArch_x64_hardwarevt
	then
		_messagePlain_good 'found: kvm'
		if [[ "$qemuHeadless" == "true" ]]
		then
			# Apparently, qemu kvm, can be unreliable if nested (eg. within VMWare Workstation VM).
			_messagePlain_good 'ignored: kvm'
		else
			qemuArgs+=(-machine accel=kvm)
		fi
	else
		_messagePlain_warn 'missing: kvm'
	fi
	
	
	# https://www.kraxel.org/repos/jenkins/edk2/
	# https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-20200515.1447.g317d84abe3.noarch.rpm
	if [[ -e "$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd ]] && [[ -e "$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd ]]
	then
		qemuArgs+=(-drive if=pflash,format=raw,readonly,file="$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd -drive if=pflash,format=raw,file="$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd)
	elif [[ -e /usr/share/OVMF/OVMF_CODE.fd ]]
	then
		qemuArgs+=(-bios /usr/share/OVMF/OVMF_CODE.fd)
	fi
	
	qemuArgs+=("${qemuSpecialArgs[@]}" "${qemuUserArgs[@]}")
	
	_messagePlain_probe _qemu_system_x86_64 "${qemuArgs[@]}"
	
	
	local currentExitStatus
	
	if [[ "$qemuHeadless" != "true" ]]
	then
		_qemu_system_x86_64 "${qemuArgs[@]}"
		currentExitStatus="$?"
	else
		_qemu_system_x86_64 "${qemuArgs[@]}" | tr -dc 'a-zA-Z0-9\n'
		currentExitStatus="$?"
	fi
	
	
	if [[ -e "$instancedVirtDir" ]] && ! _safeRMR "$instancedVirtDir"
	then
		_messageFAIL
	fi
	
	_stop "$currentExitStatus"
}
_zSpecial_qemu() {
	if ! "$scriptAbsoluteLocation" _zSpecial_qemu_sequence "$@"
	then
		_stop 1
	fi
	return 0
}






_chroot_test() {
	_messageNormal '##### init: _chroot_test'
	echo
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	sudo -n mkdir -p "$globalVirtFS"/root/temp/test_"$ubiquitiousBashIDnano"
	sudo -n cp -a "$scriptLib"/ubiquitous_bash "$globalVirtFS"/root/temp/test_"$ubiquitousBashIDnano"/
	
	_chroot chown -R root:root /root/temp/test_"$ubiquitiousBashIDnano"/
	
	if ! _chroot /root/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh _test
	then
		_messageFAIL
	fi
	
	
	# DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	_chroot rm -rf /root/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh _test
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# WARNING: DANGER: NOTICE: Do NOT distribute!
# WARNING: No production use. End-user function ONLY.
_nvidia_force_install() {
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_warn 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_bad 'WARNING: DANGER: Do NOT distribute!'
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messageNormal '##### init: _nvidia_force_install'
	echo
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	_chroot /root/_get_nvidia.sh _force_install
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

_ubDistBuild() {
	
	_create_ubDistBuild
	#_create_ubDistBuild-create
	#_create_ubDistBuild-rotten_install
	#_create_ubDistBuild-bootOnce
	#_create_ubDistBuild-rotten_install-core
	
	rm -f "$scriptLocal"/core.tar.xz > /dev/null 2>&1
	
	
	_upload_ubDistBuild_image
	
	
	
	_custom_ubDistBuild
	
	
	
}





# WARNING: DANGER: No production use. Developer function. Creates a package from "$HOME" KDE and related configuration.
_create_kde() {
	mkdir -p "$scriptLocal"
	
	cd "$HOME"
	
	
	cp -r "$scriptLib"/custom/license_package_kde "$HOME"/.license_package_kde
	
	rm -f "$scriptLocal"/package_kde.tar.xz > /dev/null 2>&1
	#-T0
	env XZ_OPT="-e9" tar --exclude='./.config/chromium' -cJvf "$scriptLocal"/package_kde.tar.xz ./.config ./.kde ./.local ./.license_package_kde
	
	rm -f "$HOME"/.license_package_kde/license.txt
	rm -f "$HOME"/.license_package_kde/CC0_license.txt
	rmdir "$HOME"/.license_package_kde
}


_refresh_anchors() {
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_get_vmImg_ubDistBuild
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_get_core_ubDistFetch
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-kde
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-core
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-create
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-bootOnce
	#cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-core
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_custom_ubDistBuild
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_package_ubDistBuild_image
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_upload_ubDistBuild_image
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_upload_ubDistBuild_custom
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_croc_ubDistBuild_image
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_croc_ubDistBuild_image_out
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_ubDistBuild
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_gparted
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_openImage
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeImage
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_openChRoot
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeChRoot
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeVBoxRaw
	
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_chroot
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_labVBox
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_zSpecial_qemu
	
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_kde
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_true
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_false
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_chroot_test
	
	
	# WARNING: DANGER: NOTICE: Do NOT distribute!
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_nvidia_force_install
}

