
# WARNING: May be untested.



######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# errata
######## ######## ######## ######## ######## ######## ######## ######## ######## ########


# *) Do NOT reboot inside qemu. Seems to cause severe KDE/plasma instability, which may cause corruption.


######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# errata
######## ######## ######## ######## ######## ######## ######## ######## ######## ########















export vboxOStype=Debian_64

_zSpecial_qemu_memory() {
	qemuUserArgs+=(-m "8704")
}


######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
if false
then

# ATTENTION: NOTICE: Most stuff from 'ops.sh' from kit is here.
type _set_ubDistBuild > /dev/null 2>&1 && _set_ubDistBuild

fi
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########





######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
if false
then

_create() {
	_custom "$@"
	
	rm -f "$scriptLocal"/*.vdi "$scriptLocal"/*.vmdk "$scriptLocal"/*.iso
	
	"$scriptAbsoluteLocation" _live "$@"
}



_custom_installDeb() {
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y --fix-broken install "$@"
}
_custom() {
	_messageNormal '_custom: cp: drivers'
	[[ -e "$scriptAbsoluteFolder"/../zDrivers ]] && sudo -n cp "$scriptAbsoluteFolder"/../zDrivers/* "$scriptLocal"/
	
	
	
	
	
	_messageNormal '_custom'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	sudo -n rm -f "$globalVirtFS"/regenerate_rootGrab
	
	_chroot hostnamectl set-hostname default
	echo "default" | sudo -n tee "$globalVirtFS"/etc/hostname
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/hosts > /dev/null
127.0.0.1	default
::1		default ip6-default ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	default
CZXWXcRMTo8EmM8i4d
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	
	
	_upstream
	_upgrade
	
	#_timezone
	
	#_regenerate
	#_regenerate_rootGrab
	
	
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	
	
	_messageNormal '_custom: cp: documentation'
	
	[[ ! -e "$scriptLocal"/ops.sh ]] && touch "$scriptLocal"/ops.sh
	sudo -n cp -f "$scriptLocal"/ops.sh "$globalVirtFS"/custom-ops.sh
	_chroot chown root:root /custom-ops.sh
	_chroot chmod 700 /custom-ops.sh
	
	[[ ! -e "$scriptLocal"/TODO.txt ]] && touch "$scriptLocal"/TODO.txt
	sudo -n cp -f "$scriptLocal"/TODO.txt "$globalVirtFS"/TODO.txt
	_chroot chown root:root /TODO.txt
	_chroot chmod 700 /TODO.txt
	
	
	
	_messageNormal '_custom: cp: home'
	rsync -ax "$scriptLocal"/home/user/. "$globalVirtFS"/home/user/.
	
	
	_messageNormal '_custom: cp: app'
	_chroot mkdir -p /root/core/installations
	[[ -e "$scriptAbsoluteFolder"/../zApp ]] && sudo -n cp "$scriptAbsoluteFolder"/../zApp/* "$globalVirtFS"/root/core/installations
	
	
	
	_messageNormal '_custom: install'
	_custom_installDeb /root/core/installations/app.deb
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y --fix-broken install
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	
	_messageNormal '_upgrade'
	_upgrade
	
	
	
	
	_messageNormal '_custom'
	
	# ATTENTION: NOTICE: Seems, 'nouveau' and 'nvidia' can usually coexist. However, neither may be as dependable (eg. usable with recent hardware) as 'Intel', 'AMD', etc. Beware such choices may be hardware-specific, (ie. not portable) etc.
	
	#_nouveau_enable
	
	
	# WARNING: DANGER: NOTICE: Do NOT distribute!
	#_chroot chmod 644 /root/_get_nvidia.sh
	#_chroot chmod 755 /root/_get_nvidia.sh
	#_nvidia_fetch_nvidia
	#_nvidia_force_install
	
	
	
	# update-grub
	#_create_ubDistBuild-bootOnce-qemu_sequence
	
	
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	echo | sudo -n tee "$globalVirtFS"/simpleCrypt_ext4
	
	sudo -n rm -f "$globalVirtFS"/regenerate
	sudo -n rm -f "$globalVirtFS"/regenerate_rootGrab
	
	echo | sudo -n tee "$globalVirtFS"/regenerate
	
	# CAUTION: Only add this if appropriate.
	echo | sudo -n tee "$globalVirtFS"/regenerate_rootGrab
	
	
	sudo -n rm -f "$globalVirtFS"/home/user/core/platformBuilder/_self/self/package_image.tar.xz
	sudo -n rm -f "$globalVirtFS"/home/user/core/platformBuilder/distllc/package_image.tar.xz
	sudo -n dd if=/dev/zero of="$globalVirtFS"/fill bs=1M status=progress
	sudo -n rm -f "$globalVirtFS"/fill
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	
	
	
	
	_messageNormal '_custom: package'
	
	_package_ubDistBuild_image
	
	
	_messageNormal '_custom: cp: self'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	sudo -n mkdir -p "$globalVirtFS"/home/user/core/platformBuilder/_self/self
	_chroot chown user:user /home/user/core/platformBuilder/_self/self
	_chroot chown user:user /home/user/core/platformBuilder/_self
	_chroot chown user:user /home/user/core/platformBuilder
	_chroot chown user:user /home/user/core
	_chroot chown user:user /home/user
	
	sudo -n cp -a "$globalVirtFS"/home/user/ubDistBuild "$globalVirtFS"/home/user/core/platformBuilder/_self/self/
	sudo -n cp -f "$scriptLocal"/package_image.tar.xz "$globalVirtFS"/home/user/core/platformBuilder/_self/self/package_image.tar.xz
	_chroot chown user:user /home/user/core/platformBuilder/_self/self/package_image.tar.xz
	
	sudo -n mkdir -p "$globalVirtFS"/home/user/core/platformBuilder/distllc
	_chroot chown user:user /home/user/core/platformBuilder/distllc
	_chroot chown user:user /home/user/core/platformBuilder
	_chroot chown user:user /home/user/core
	_chroot chown user:user /home/user
	
	sudo -n cp -a "$globalVirtFS"/home/user/ubDistBuild "$globalVirtFS"/home/user/core/platformBuilder/distllc/
	sudo -n cp -f "$scriptAbsoluteFolder"/../distllc/package_image.tar.xz "$globalVirtFS"/home/user/core/platformBuilder/distllc/package_image.tar.xz
	_chroot chown user:user /home/user/core/platformBuilder/distllc/package_image.tar.xz
	
	
	sudo -n ln -s ../../distllc "$globalVirtFS"/home/user/core/platformBuilder/_self/self/distllc
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	
	
	_messageNormal '_custom: end'
	rm -f "$scriptLocal"/package_image.tar.xz
	
	return 0
}


# End user function. No production use. Usually '_zSpecial_qemu_chroot' will be more appropriate , and will be called automatically after '_zSpecial_qemu' .
_enable_regenerate_rootGrab() {
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	echo | sudo -n tee "$globalVirtFS"/regenerate_rootGrab
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	return 0
}




_upstream() {
	#! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	
	#true
	
	
	#! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	
	true
	return 0
}




_upgrade() {
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	sudo -n cp -f "$scriptLib"/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/
	sudo -n chmod 755 "$globalVirtFS"/root/_get_nvidia.sh
	
	
	
	
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	_chroot sudo -n cp -f /rotten_install.sh /home/"$custom_user"/rottenScript.sh
	_chroot sudo -n chown "user:user" "/home/""$custom_user""/rottenScript.sh"
	_chroot sudo -n chmod "700" "/home/""$custom_user""/rottenScript.sh"
	
	_chroot sudo -n cp -f /rotten_install.sh /root/rottenScript.sh
	_chroot sudo -n chmod 700 /root/rottenScript.sh
	
	
	#[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && _messageFAIL
	#sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	#[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	#sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	sudo -n cp -f "$scriptAbsoluteLocation" "$globalVirtFS"/ubiquitous_bash.sh
	[[ ! -e "$globalVirtFS"/ubiquitous_bash.sh ]] && _messageFAIL
	sudo -n chmod 755 "$globalVirtFS"/ubiquitous_bash.sh
	
	
	sudo -n mkdir -p "$globalVirtFS"/root/core_rG/flipKey/_local
	sudo -n cp -f "$scriptLib"/setup/rootGrab/_rootGrab.sh "$globalVirtFS"/root/_rootGrab.sh
	sudo -n chmod 700 "$globalVirtFS"/root/_rootGrab.sh
	sudo -n cp -f "$scriptLib"/flipKey/flipKey "$globalVirtFS"/root/core_rG/flipKey/flipKey
	sudo -n chmod 700 "$globalVirtFS"/root/core_rG/flipKey/flipKey
	
	! _chroot /root/_rootGrab.sh _hook && _messageFAIL
	
	
	
	#! _chroot /rotten_install.sh _custom_kde_drop && _messageFAIL
	
	
	
	
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade
	
	
	_chroot apt-get -y clean
	_chroot sudo apt-get autoremove --purge
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	return 0
}


_timezone() {
	! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	[[ -e "$globalVirtFS"/usr/share/zoneinfo/America/New_York ]] && _chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
	_chroot timedatectl set-timezone US/Eastern
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
	return 0
}



_regenerate() {
	_messageNormal '_regenerate: chroot: rotten_install: _regenerate'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	if [[ -e "$scriptLocal"/core.tar.xz ]] && ! [[ -e "$globalVirtFS"/home/user/core ]]
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
	! _chroot /rotten_install.sh _regenerate && _messageFAIL
	#sudo -n rm -f "$globalVirtFS"/in_chroot
	
	
	
	
	
	
	
	_messageNormal 'chroot: rotten_install: password'
	
	local currentPassword
	currentPassword=$(_uid 12)
	
	echo "$currentPassword"
	
	echo root':'"$currentPassword" | _chroot chpasswd
	
	echo user':'"$currentPassword" | _chroot chpasswd
	
	
	
	
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}



_regenerate_rootGrab() {
	[[ -e "$globalVirtFS"/root/_rootGrab.sh ]] && ! _chroot /root/_rootGrab.sh _create && _messageFAIL
	return 0
}


fi
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
















######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
if false
then

# Creates a raw VM image. Default Hybrid/UEFI partitioning and formatting.
# ATTENTION: Override, if necessary.
_createVMimage() {
	_messageNormal '##### _createVMimage'
	
	mkdir -p "$scriptLocal"
	
	
	export vmImageFile="$scriptLocal"/vm.img
	[[ -e "$vmImageFile" ]] && _messagePlain_good 'exists: '"$vmImageFile" && return 0
	[[ -e "$scriptLocal"/vm.img ]] && _messagePlain_good 'exists: '"$vmImageFile" && return 0
	
	[[ -e "$lock_open" ]]  && _messagePlain_bad 'bad: locked!' && _messageFAIL && _stop 1
	[[ -e "$scriptLocal"/l_o ]]  && _messagePlain_bad 'bad: locked!' && _messageFAIL && _stop 1
	
	! [[ $(df --block-size=1000000000 --output=avail "$scriptLocal" | tr -dc '0-9') -gt "25" ]] && _messageFAIL && _stop 1
	
	
	
	local imagedev
	
	_open
	
	export vmImageFile="$scriptLocal"/vm.img
	[[ -e "$vmImageFile" ]] && _messagePlain_bad 'exists: '"$vmImageFile" && _messageFAIL && _stop 1
	
	
	_messageNormal 'create: vm.img'
	
	export vmSize=86016
	_createRawImage
	
	
	_messageNormal 'partition: vm.img'
	sudo -n parted --script "$vmImageFile" 'mklabel gpt'
	
	# Unusual.
	#   EFI, Image/Root.
	# Former default, only preferable if disk is strictly spinning CAV and many more bits per second with beginning tracks.
	#   Swap, EFI, Image/Root.
	# Compromise. May have better compatibility, may reduce CLV (and zoned CAV) speed changes from slowest tracks at beginning of some optical discs.
	#   EFI, Swap, Image/Root.
	# Expect <8MiB usage of EFI parition FAT32 filesystem, ~28GiB usage of Image/Root partition ext4 filesystem.
	# 512MiB EFI, 5120MiB Swap, remainder Image/Root
	# https://www.compuhoy.com/what-is-difference-between-bios-and-efi/
	#  'Does EFI partition have to be first?' 'UEFI does not impose a restriction on the number or location of System Partitions that can exist on a system. (Version 2.5, p. 540.) As a practical matter, putting the ESP first is advisable because this location is unlikely to be impacted by partition moving and resizing operations.'
	# http://blog.arainho.me/grub/gpt/arch-linux/2016/01/14/grub-on-gpt-partition.html
	#  'at the first 2GB of the disk with toggle bios_grub used for booting'
	
	# CAUTION: *As DEFAULT*, must match other definitions (eg. _set_ubDistBuild , 'core.sh' , 'ops.sh' , ubiquitous_bash , etc) .
	# NTFS, Recovery, partitions should not have set values in any other functions. Never used - documentation only.
	# Swap, partition should only have set values in this and fstab functions. Never used elsewhere.
	# x64-bios , raspbian , x64-efi
	export ubVirtImage_doNotOverride="true"
	export ubVirtPlatformOverride='x64-efi'
	export ubVirtImageBIOS=p1
	export ubVirtImageEFI=p2
	export ubVirtImageNTFS=
	export ubVirtImageRecovery=
	export ubVirtImageSwap=p3
	export ubVirtImageBoot=p4
	export ubVirtImagePartition=p5
	
	
	
	
	# ATTENTION: NOTICE: Larger EFI partition may be more compatible. Larger Swap partition may be more useful for hibernation.
	
	# BIOS
	sudo -n parted --script "$vmImageFile" 'mkpart primary ext2 1 2'
	sudo -n parted --script "$vmImageFile" 'set 1 bios_grub on'
	
	
	# EFI
	#sudo -n parted --script "$vmImageFile" 'mkpart EFI fat32 '"2"'MiB '"514"'MiB'
	sudo -n parted --script "$vmImageFile" 'mkpart EFI fat32 '"2"'MiB '"74"'MiB'
	sudo -n parted --script "$vmImageFile" 'set 2 msftdata on'
	sudo -n parted --script "$vmImageFile" 'set 2 boot on'
	sudo -n parted --script "$vmImageFile" 'set 2 esp on'
	
	
	# Swap
	#sudo -n parted --script "$vmImageFile" 'mkpart primary '"514"'MiB '"5633"'MiB'
	#sudo -n parted --script "$vmImageFile" 'mkpart primary '"514"'MiB '"3073"'MiB'
	sudo -n parted --script "$vmImageFile" 'mkpart primary '"74"'MiB '"98"'MiB'
	
	
	# Boot
	sudo -n parted --script "$vmImageFile" 'mkpart primary '"98"'MiB '"610"'MiB'
	
	
	# Root
	sudo -n parted --script "$vmImageFile" 'mkpart primary '"610"'MiB '"86015"'MiB'
	
	
	
	
	sudo -n parted --script "$vmImageFile" 'unit MiB print'
	
	
	_close
	
	
	# Format partitions .
	_messageNormal 'format: vm.img'
	#"$scriptAbsoluteLocation" _loopImage_sequence || _stop 1
	! "$scriptAbsoluteLocation" _openLoop && _messagePlain_bad 'fail: _openLoop' && _messageFAIL
	
	mkdir -p "$globalVirtFS"
	"$scriptAbsoluteLocation" _checkForMounts "$globalVirtFS" && _messagePlain_bad 'bad: mounted: globalVirtFS' && _messageFAIL && _stop 1
	#local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	local imagepart
	local loopdevfs
	
	# Compression from btrfs may free up ~8GB . Some performance degradation may result if files with many random writes (eg. COW VM images) are used with btrfs .
	# https://www.phoronix.com/scan.php?page=article&item=btrfs-zstd-compress&num=4
	# https://btrfs.wiki.kernel.org/index.php/Compression
	# https://unix.stackexchange.com/questions/394973/why-would-i-want-to-disable-copy-on-write-while-creating-qemu-images
	# https://gist.github.com/niflostancu/03810a8167edc533b1712551d4f90a14
	
	# WARNING: Compression/btrfs of boot partition may cause BIOS compatibility issues.
	imagepart="$imagedev""$ubVirtImageBoot"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkfs.ext2 -e remount-ro -E lazy_itable_init=0,lazy_journal_init=0 -m 0 "$imagepart" || _stop 1
	#sudo -n mkfs.btrfs --checksum xxhash -M -d single "$imagepart" || _stop 1
	
	imagepart="$imagedev""$ubVirtImageEFI"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkfs.vfat -F 32 -n EFI "$imagepart" || _stop 1
	
	imagepart="$imagedev""$ubVirtImagePartition"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkfs.ext4 -e remount-ro -E lazy_itable_init=0,lazy_journal_init=0 -m 0 "$imagepart" || _stop 1
	#sudo -n mkfs.btrfs --checksum xxhash -M -d single "$imagepart" || _stop 1
	
	imagepart="$imagedev""$ubVirtImageSwap"
	loopdevfs=$(sudo -n blkid -s TYPE -o value "$imagepart" | tr -dc 'a-zA-Z0-9')
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkswap "$imagepart" || _stop 1
	
	#"$scriptAbsoluteLocation" _umountImage || _stop 1
	! "$scriptAbsoluteLocation" _closeLoop && _messagePlain_bad 'fail: _closeLoop' && _messageFAIL
	return 0
}

# By default, as included from upstream 'ubiquitous_bash', will convert from default 'x64-efi' partitions, to same default configured 'x64-efi' paritions, with the _createVMimage override having changed the root filesystem from default 'btrfs' to 'ext4' .

#_convertVMimage_sequence()
#_convertVMimage()






# ATTENTION: Usually only necessary to change 'btrfs' and associated options to 'ext4' options .
_createVMfstab() {
	_messageNormal 'os: globalVirtFS: write: fs: _createVMfstab'
	
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	[[ ! -e "$imagedev" ]] && _messageFAIL
	
	sudo -n mkdir -p "$globalVirtFS"/media/bootdisc
	sudo -n chmod 755 "$globalVirtFS"/media/bootdisc
	
	
	# https://gist.github.com/varqox/42e213b6b2dde2b636ef#edit-fstab-file
	
	#btrfs rescue zero-log /dev/sda5
	
	local ubVirtImagePartition_UUID
	ubVirtImagePartition_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImagePartition" | tr -dc 'a-zA-Z0-9\-')
	
	# ATTENTION: Overrides with ext4 , not btrfs , root fs .
	echo 'UUID='"$ubVirtImagePartition_UUID"' / ext4 errors=remount-ro 0 1' | sudo -n tee "$globalVirtFS"/etc/fstab
	#echo 'UUID='"$ubVirtImagePartition_UUID"' / btrfs defaults,compress=zstd:1,notreelog 0 1' | sudo -n tee "$globalVirtFS"/etc/fstab
	#echo 'UUID='"$ubVirtImagePartition_UUID"' / btrfs defaults,compress=zstd:1,notreelog,discard 0 1' | sudo -n tee "$globalVirtFS"/etc/fstab
	
	
	
	
	# initramfs-update, from chroot, may not enable hibernation/resume... may be device specific
	
	if [[ "$ubVirtImageSwap" != "" ]]
	then
		local ubVirtImageSwap_UUID
		ubVirtImageSwap_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImageSwap" | tr -dc 'a-zA-Z0-9\-')
	fi
	
	echo '#UUID='"$ubVirtImageSwap_UUID"' swap swap defaults 0 0' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	
	
	if [[ "$ubVirtImageBoot" != "" ]]
	then
		local ubVirtImageBoot_UUID
		ubVirtImageBoot_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImageBoot" | tr -dc 'a-zA-Z0-9\-')
	fi
	
	echo 'UUID='"$ubVirtImageBoot_UUID"' /boot ext2 defaults 0 1' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	
	
	if [[ "$ubVirtImageEFI" != "" ]]
	then
		local ubVirtImageEFI_UUID
		ubVirtImageEFI_UUID=$(sudo -n blkid -s UUID -o value "$imagedev""$ubVirtImageEFI" | tr -dc 'a-zA-Z0-9\-')
	fi
	
	echo 'UUID='"$ubVirtImageEFI_UUID"' /boot/efi vfat umask=0077 0 1' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	
	
	if ! sudo -n cat "$globalVirtFS"/etc/fstab | grep 'uk4uPhB663kVcygT0q' | grep 'bootdisc' > /dev/null 2>&1
	then
		echo 'LABEL=uk4uPhB663kVcygT0q /media/bootdisc iso9660 ro,nofail 0 0' | sudo -n tee -a "$globalVirtFS"/etc/fstab
	fi
	
	return 0
}












# ATTENTION: NOTICE: Recommend deleting any directories which may have obsolete or large software (eg. ~/.core , ~/.ubcore , ~/.bin , etc).
_preserve_home_tmp() {
	[[ -e "$scriptLocal"/home_tmp ]] && _messageError 'FAIL: exists: home_tmp' && _stop 1
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	#sudo -n rm -f "$globalVirtFS"/home/user/core/platformBuilder/_self/self/package_image.tar.xz
	#sudo -n rm -f "$globalVirtFS"/home/user/core/platformBuilder/distllc/package_image.tar.xz
	
	mkdir -p "$scriptLocal"/home_tmp/user
	#sudo -n rsync -ax "$globalVirtFS"/home/user/. "$scriptLocal"/home_tmp/user/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.cache
	sudo -n rsync -ax "$globalVirtFS"/home/user/.cache/. "$scriptLocal"/home_tmp/user/.cache/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.config
	sudo -n rsync -ax "$globalVirtFS"/home/user/.config/. "$scriptLocal"/home_tmp/user/.config/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.kde
	sudo -n rsync -ax "$globalVirtFS"/home/user/.kde/. "$scriptLocal"/home_tmp/user/.kde/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.kde.bak
	sudo -n rsync -ax "$globalVirtFS"/home/user/.kde.bak/. "$scriptLocal"/home_tmp/user/.kde.bak/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.local
	sudo -n rsync -ax "$globalVirtFS"/home/user/.local/. "$scriptLocal"/home_tmp/user/.local/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.parsec
	sudo -n rsync -ax "$globalVirtFS"/home/user/.parsec/. "$scriptLocal"/home_tmp/user/.parsec/.
	
	mkdir -p "$scriptLocal"/home_tmp/user/.xournal
	sudo -n rsync -ax "$globalVirtFS"/home/user/.xournal/. "$scriptLocal"/home_tmp/user/.xournal/.
	
	
	sudo -n rsync -ax "$globalVirtFS"/home/user/.bash_history "$scriptLocal"/home_tmp/user/.
	sudo -n rsync -ax "$globalVirtFS"/home/user/.bash_logout "$scriptLocal"/home_tmp/user/.
	sudo -n rsync -ax "$globalVirtFS"/home/user/.gtkrc-2.0 "$scriptLocal"/home_tmp/user/.
	
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

_import_home_tmp() {
	[[ ! -e "$scriptLocal"/home_tmp ]] && _messageError 'FAIL: missing: home_tmp' && _stop 1
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	mkdir -p "$scriptLocal"/home_tmp/user
	sudo -n rsync -ax "$scriptLocal"/home_tmp/user/. "$globalVirtFS"/home/user/.
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

fi
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########















######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
if false
then

_live_grub_here() {
	cat <<'CZXWXcRMTo8EmM8i4d'

insmod all_video

search --set=root --file /ROOT_TEXT

#set default="0"
#set default="1"
set default="2"
set timeout=1

menuentry "Live" {
    #linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0 mem=3712M resume=UUID=469457fc-293f-46ec-92da-27b5d0c36b17
    #linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0 mem=3712M resume=PARTUUID=469457fc-293f-46ec-92da-27b5d0c36b17
    linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0 mem=3712M resume=/dev/sda5
    initrd /initrd
}

menuentry "Live - ( persistence )" {
    linux /vmlinuz boot=live config debug=1 noeject persistence persistence-path=/persist persistence-label=bulk persistence-storage=directory selinux=0 mem=3712M resume=/dev/sda5
    initrd /initrd
}

menuentry "Live - ( hint: ignored: resume disabled ) ( mem: all )" {
    linux /vmlinuz boot=live config debug=1 noeject nopersistence selinux=0
    initrd /initrd
}

CZXWXcRMTo8EmM8i4d
}

fi
######## ######## ######## ######## ######## ######## ######## ######## ######## ########
# BLOCK COMMENT
######## ######## ######## ######## ######## ######## ######## ######## ######## ########

