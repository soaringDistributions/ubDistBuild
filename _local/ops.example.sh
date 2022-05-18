
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


_custom() {
	_upstream
	_upgrade
	
	#_timezone
	
	#_regenerate
	#_regenerate_rootGrab
	
	
	# ATTENTION: NOTICE: Seems, 'nouveau' and 'nvidia' can usually coexist. However, neither may be as dependable (eg. usable with recent hardware) as 'Intel', 'AMD', etc. Beware such choices may be hardware-specific, (ie. not portable) etc.
	
	#_nouveau_enable
	
	# WARNING: DANGER: NOTICE: Do NOT distribute!
	#_nvidia_fetch_nvidia
	#_nvidia_force_install
	
	
	
	# update-grub
	#_create_ubDistBuild-bootOnce-qemu_sequence
}




_upstream() {
	#! "$scriptAbsoluteLocation" _openChRoot && _messageFAIL
	
	
	#true
	
	
	#! "$scriptAbsoluteLocation" _closeChRoot && _messageFAIL
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
	
	
	[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	sudo -n cp -f "$scriptAbsoluteLocation" "$globalVirtFS"/ubiquitous_bash.sh
	[[ ! -e "$globalVirtFS"/ubiquitous_bash.sh ]] && _messageFAIL
	sudo -n chmod 755 "$globalVirtFS"/ubiquitous_bash.sh
	
	
	sudo -n mkdir -p "$globalVirtFS"/root/core_rG/flipKey/_local
	sudo -n cp -f "$scriptLib"/setup/rootGrab/_rootGrab.sh "$globalVirtFS"/root/_rootGrab.sh
	sudo -n chmod 700 "$globalVirtFS"/root/_rootGrab.sh
	sudo -n cp -f "$scriptLib"/flipKey/flipKey "$globalVirtFS"/root/core_rG/flipKey/flipKey
	sudo -n chmod 700 "$globalVirtFS"/root/core_rG/flipKey/flipKey
	
	! _chroot /root/_rootGrab.sh _hook && _messageFAIL
	
	
	
	! _chroot /rotten_install.sh _custom_kde_drop && _messageFAIL
	
	
	
	
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
	! _chroot /rotten_install.sh _regenerate && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	
	
	
	
	
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

