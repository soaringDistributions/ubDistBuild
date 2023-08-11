
# Documentation, mostly, and a very abbreviated 'cheat sheet' at that.
# Local experiment. Should closely resemble corresponding devops workflow (eg. build.yml).
# Host should either be equivalent to the desired CI (eg. Github Actions standard runner), or ubdist/Linux, or through built-in ubcp/MSW .

_devops_sep() {
    [[ "$1" == "begin" ]] && echo -e '\033[0;95;103m  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  \033[0m'
    echo -e '\033[0;95;103m                                            \033[0m'
    echo
    echo -e '\033[0;33;40m  '"$1": "$2"'  \033[0m'
    echo
    echo -e '\033[0;95;103m                                            \033[0m'
    [[ "$1" == "end" ]] && echo -e '\033[0;95;103m  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  \033[0m'

    [[ "$1" != "begin" ]] && echo
    echo > /dev/null
}

_devops_function() {
    #_devops_sep begin ${FUNCNAME[0]}
    _devops_sep begin "$@"

    "$@"

   # _devops_sep end ${FUNCNAME[0]}
    _devops_sep end "$@"
}
_dof() {
    _devops_function "$@"
}

_devops_special_getMinimal_getMost() {
    _getMinimal_cloud
    _getMinimal_cloud
    _getMost_ubuntu22-VBoxManage
}




_devops_install() {
    clear

    export skimfast="true"
    export devfast="true"
    
    _dof _devops_special_getMinimal_getMost
}


_devops_experiment() {
    clear
    _devops_sep begin ${FUNCNAME[0]}


    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# WARNING: Do NOT use twice. Usually already effectively called by '_create_ubDistBuild-rotten_install' .
	#_create_ubDistBuild-rotten_install-bootOnce
	
	
	## ATTENTION: NOTICE: Resets any changes to crontab (ie. by rotten_install ).
	##echo | _chroot crontab '-'
	##echo | sudo -n -u user bash -c "crontab -"
	##echo '@reboot cd '/home/user'/ ; '/home/user'/rottenScript.sh _run' | sudo -n -u user bash -c "crontab -"
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/.config/autostart
	##_here_bootdisc_startup_xdg | sudo -n tee "$globalVirtFS"/home/user/.config/autostart/startup.desktop > /dev/null
	##_chroot chown -R user:user /home/user/.config
	##_chroot chmod 555 /home/user/.config/autostart/startup.desktop
	
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/___quick
	##echo 'sudo -n mount -t fuse.vmhgfs-fuse -o allow_other,uid=$(id -u "$USER"),gid=$(id -g "$USER") .host: "$HOME"/___quick' | sudo -n tee "$globalVirtFS"/home/user/___quick/mount.sh
	##_chroot chown -R user:user /home/user/___quick
	##_chroot chmod 755 /home/user/___quick/mount.sh
	
	##( _chroot crontab -l ; echo '@reboot /media/bootdisc/rootnix.sh > /var/log/rootnix.log 2>&1' ) | _chroot crontab '-'
	
	##( _chroot sudo -n -u user bash -c "crontab -l" ; echo '@reboot cd /home/'"$custom_user"'/.ubcore/ubiquitous_bash/lean.sh _unix_renice_execDaemon' ) | _chroot sudo -n -u user bash -c "crontab -"
	
	# ### NOTICE
	# /usr/lib/virtualbox/vboxdrv.sh
	#  KERN_VER=`uname -r`
	#  ! $MODPROBE vboxdrv > /dev/null 2>&1
	# /usr/share/virtualbox/src/vboxhost/build_in_tmp
	#  MAKE_JOBS


	sudo -n mv "$globalVirtFS"/usr/bin/uname "$globalVirtFS"/usr/bin/uname-orig
	sudo -n mv "$globalVirtFS"/bin/uname "$globalVirtFS"/bin/uname-orig

	sudo -n rm -f "$globalVirtFS"/usr/bin/uname
	sudo -n rm -f "$globalVirtFS"/bin/uname

	cat << 'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/usr/bin/uname > /dev/null
#!/bin/bash

local currentTopKernel 2>/dev/null
currentTopKernel=$(sudo -n cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)

if [[ "$1" == "-r" ]] && [[ "$currentTopKernel" != "" ]]
then
	echo "$currentTopKernel"
	exit "$?"
fi

if [[ -e /usr/bin/uname-orig ]]
then
	/usr/bin/uname-orig "$@"
	exit "$?"
fi

if [[ -e /bin/uname-orig ]]
then
	/bin/uname-orig "$@"
	exit "$?"
fi

exit 1
CZXWXcRMTo8EmM8i4d

	sudo -n chown root:root "$globalVirtFS"/usr/bin/uname
	sudo -n chmod 755 "$globalVirtFS"/usr/bin/uname


	_messagePlain_probe _chroot /sbin/rcvboxdrv setup
	_chroot /sbin/rcvboxdrv setup

	_messagePlain_probe /sbin/rcvboxdrv setup all
	_chroot /sbin/rcvboxdrv setup all

	_messagePlain_probe /sbin/rcvboxdrv setup $(_chroot cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)
	_chroot /sbin/rcvboxdrv setup $(_chroot cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)


	_messagePlain_probe _chroot /sbin/vboxconfig
	_chroot /sbin/vboxconfig

	_messagePlain_probe _chroot /sbin/vboxconfig
	_chroot /sbin/vboxconfig --nostart
	
	_messagePlain_probe '__________________________________________________'
	_messagePlain_probe 'probe: kernel modules: '"sudo -n find / -xdev -name 'vboxdrv.ko'"
	sudo -n find "$globalVirtFS" -xdev -name 'vboxdrv.ko'
	_messagePlain_probe '__________________________________________________'

	sudo -n rm -f "$globalVirtFS"/usr/bin/uname
	sudo -n rm -f "$globalVirtFS"/bin/uname

	sudo -n mv -f "$globalVirtFS"/usr/bin/uname-orig "$globalVirtFS"/usr/bin/uname
	sudo -n mv -f "$globalVirtFS"/bin/uname-orig "$globalVirtFS"/bin/uname

	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	

    _devops_sep end ${FUNCNAME[0]}
}


_devops() {
    clear

    export skimfast="true"
    export devfast="true"
    
    #_devops_install

    rm -f "$scriptLocal"/ubcp
    _dof _create_ubDistBuild-create
    _dof _create_ubDistBuild-rotten_install
}

