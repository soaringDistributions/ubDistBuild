
# Documentation, mostly, and a very abbreviated 'cheat sheet' at that.
# Local experiment. Should closely resemble corresponding devops workflow (eg. build.yml).
# Host should either be equivalent to the desired CI (eg. Github Actions standard runner), or ubdist/Linux, or through built-in ubcp/MSW .


#clear ; wsl -d ubdist_fallback ./ubiquitous_bash.sh _devops 2>&1 | tee ./_local/devops.log
#less -R ./_local/devops.log
#tail -f ./_local/devops.log
_devops() {
    clear
	local functionEntryPWD="$PWD"

    export skimfast="true"
    export devfast="true"
	export qemuNoKVM="false"
	
	sudo -n rm -f "$scriptLocal"/vm.img
	[[ -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'bad: fail: rm: vm.img' && return 0
	sudo -n rm -f "$scriptLocal"/vm-live.iso
	[[ -e "$scriptLocal"/vm-live.iso ]] && _messagePlain_bad 'bad: fail: rm: vm-live.iso' && return 0
	sudo -n rm -f "$scriptLocal"/package_rootfs.tar
	[[ -e "$scriptLocal"/package_rootfs.tar ]] && _messagePlain_bad 'bad: fail: rm: package_rootfs.tar' && return 0

	sudo -n rm -f "$scriptLocal"/package_rootfs.tar.flx
	[[ -e "$scriptLocal"/package_rootfs.tar.flx ]] && _messagePlain_bad 'bad: fail: rm: package_rootfs.tar.flx' && return 0

	# Notable, due to usability of '_userVBox' through Cygwin/MSW.
	#sudo -n rm -f "$scriptLocal"/vm.vdi
    
    #_devops_install



    _dof _create_ubDistBuild-create

    _dof _create_ubDistBuild-rotten_install

	_dof _chroot_test

	_dof _create_ubDistBuild-bootOnce

	#_fetchCore
	_do_fetchCore() {
		#cd "$scriptAbsoluteFolder"
		#cd _local
		cd "$scriptLocal"
		git clone https://github.com/soaringDistributions/ubDistFetch.git
		cd ubDistFetch
		_gitBest pull
		./_ubDistFetch.bat
	}
	_dof _do_fetchCore

	_dof _create_ubDistBuild-rotten_install-core

	_dof _create_ubDistBuild-install-ubDistBuild


	_do_scribeInfo() {
		! ./ubiquitous_bash.sh _openChRoot && exit 1
		! echo devops | ./ubiquitous_bash.sh _chroot tee /info-devops && exit 1
		#! git rev-parse --short HEAD | ./ubiquitous_bash.sh _chroot tee -a /info-devops && exit 1
		#! git log --pretty=format:'%h' -n 1 | ./ubiquitous_bash.sh _chroot tee -a /info-devops && exit 1
		! git log --pretty=format:'%H' -n 1 | ./ubiquitous_bash.sh _chroot tee -a /info-devops && exit 1
		! date +"%Y-%m-%d" | ./ubiquitous_bash.sh _chroot tee -a /info-devops && exit 1
		! ./ubiquitous_bash.sh _closeChRoot && exit 1
	}
	_dof _do_scribeInfo





	#_dof _package_ubDistBuild_image
	#_dof _ubDistBuild_split
	#_dof _package_rm


	#export current_diskConstrained="true"
	_dof _convert-rootfs
	_do_unpackage_rootfs() {
		cd "$scriptLocal"
		cat "$scriptLocal"/"package_rootfs.tar.flx" | lz4 -d -c > "$scriptLocal"/package_rootfs.tar
	}
	_dof _do_unpackage_rootfs
	#_dof _ubDistBuild_split-rootfs
	#_dof _package_rm


	#_fetchAccessories extendedInterface
	_do_fetchAccessories_extendedInterface() {
		#cd "$scriptAbsoluteFolder"
		#cd _local
		cd "$scriptLocal"
		git clone https://github.com/mirage335-colossus/extendedInterface.git
		cd extendedInterface
		mkdir -p ../extendedInterface-accessories/integrations/ubcp
		#-H "Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}"
		curl -L -o ../extendedInterface-accessories/integrations/ubcp/package_ubcp-core.7z  $(curl -s "https://api.github.com/repos/mirage335-colossus/ubiquitous_bash/releases" | jq -r ".[] | select(.name == \"internal\") | .assets[] | select(.name == \"package_ubcp-core.7z\") | .browser_download_url" | sort -n -r | head -n1)  
		./ubiquitous_bash.sh _build_extendedInterface-fetch
	}
	_dof _do_fetchAccessories_extendedInterface

	#_fetchAccessories ubDistBuild
	_do_fetchAccessories_ubDistBuild() {
		#cd "$scriptAbsoluteFolder"
		#cd _local
		cd "$scriptLocal"
		git clone https://github.com/soaringDistributions/ubDistBuild.git
		cd ubDistBuild
		mkdir -p ../ubDistBuild-accessories/integrations/ubcp
		#-H "Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}"
		curl -L -o ../ubDistBuild-accessories/integrations/ubcp/package_ubcp-core.7z  $(curl -s "https://api.github.com/repos/mirage335-colossus/ubiquitous_bash/releases" | jq -r ".[] | select(.name == \"internal\") | .assets[] | select(.name == \"package_ubcp-core.7z\") | .browser_download_url" | sort -n -r | head -n1)  
		./ubiquitous_bash.sh _build_ubDistBuild-fetch
	}
	_dof _do_fetchAccessories_ubDistBuild

	#export current_diskConstrained="true"
	_dof _convert-live
	#_dof _ubDistBuild_split-live
	#_dof _package_rm




	cd "$functionEntryPWD"
}


_devops_install() {
    clear

    export skimfast="true"
    export devfast="true"
    
    _dof _getMinimal_cloud
	_dof _getMinimal_cloud
	
    _dof _getMost_ubuntu22-VBoxManage

	# _getMost-xvfb
	_do_getMost-xvfb() {
		sudo -n env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install --install-recommends -y xvfb
	}
	_dof _do_getMost-xvfb
}


_devops_continue() {
    export skimfast="true"
    export devfast="true"
	export qemuNoKVM="false"
	export qemuHeadless="false"

	#_dof _chroot_test

	_dof _create_ubDistBuild-bootOnce
}



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
	local functionEntryPWD="$PWD"
	cd "$scriptAbsoluteFolder"
	local functionEntryDISPLAY="$DISPLAY"

    "$@"

	export DISPLAY="$functionEntryDISPLAY"
	[[ "$DISPLAY" == "" ]] && unset DISPLAY
	cd "$functionEntryPWD"
    # _devops_sep end ${FUNCNAME[0]}
    _devops_sep end "$@"
}
_dof() {
    _devops_function "$@"
}






_devops_experiment() {
    clear
    _devops_sep begin ${FUNCNAME[0]}


    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	

	_messagePlain_probe /sbin/rcvboxdrv setup all
	_chroot /sbin/rcvboxdrv setup all


	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	

    _devops_sep end ${FUNCNAME[0]}
}

