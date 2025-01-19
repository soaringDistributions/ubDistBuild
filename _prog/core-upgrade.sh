
# WARNING: No production use. May be untested.

# WARNING: Upgrade functions are also called by 'custom' scripts to ensure such binaries as 'extIface.exe' are most recent.

# ATTENTION: This 'upgrade' functionality is a non-essential and intentionally less than comprehensive development tool to reduce cycle time for 'ubDistBuild' by cautiously and quickly upgrading only repositories, etc, with still rapidly developing essential functionality.



# ATTENTION
#./ubiquitous_bash.sh _create_ubDistBuild-rotten_install-kde


# May be substituted in practice for '_zSpecial_report-FORCE' if there are issues with this function.
_upgrade_report() {
    local functionEntryPWD
    functionEntryPWD="$PWD"
    
    echo
    echo 'init: _upgrade_report'
    echo

	! _messagePlain_probe_cmd _openChRoot && _messagePlain_bad 'fail: openChroot' && _messageFAIL

    _messageNormal 'init: _upgrade_report: dpkg'
    #_chroot dpkg -l | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
    _chroot dpkg --get-selections | cut -f1 | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
    sudo -n cp -f "$globalVirtFS"/dpkg "$scriptLocal"/dpkg
    sudo -n chown "$USER":"$USER" "$scriptLocal"/dpkg
    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _upgrade_report: dpkg'

    _messageNormal 'init: _upgrade_report: binReport'
    _chroot find /bin/ /usr/bin/ /sbin/ /usr/sbin/ | sudo -n tee "$globalVirtFS"/binReport > /dev/null
    _chroot find /home/user/.nix-profile/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
    _chroot find /home/user/.gcloud/google-cloud-sdk/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null
    _chroot find /home/user/.ebcli-virtual-env/executables | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
    sudo -n cp -f "$globalVirtFS"/binReport "$scriptLocal"/binReport
    sudo -n chown "$USER":"$USER" "$scriptLocal"/binReport
    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _upgrade_report: binReport'

    _messageNormal 'init: _upgrade_report: coreReport'
    _messagePlain_probe "_chroot find /home/user/core/installations /home/user/core/infrastructure /home/user/core/variant /home/user/core/info -not \( -path \*.git\* -prune \) | grep -v '_local/h' | sudo -n tee ""$globalVirtFS""/coreReport > /dev/null"
    _chroot find /home/user/core/installations /home/user/core/infrastructure /home/user/core/variant /home/user/core/info -not \( -path \*.git\* -prune \) | grep -v '_local/h' | sudo -n tee "$globalVirtFS"/coreReport > /dev/null
	sudo -n cp -f "$globalVirtFS"/coreReport "$scriptLocal"/coreReport
	sudo -n chown "$USER":"$USER" "$scriptLocal"/coreReport
    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _upgrade_report: coreReport'
	
	! _messagePlain_probe_cmd _closeChRoot && _messagePlain_bad 'fail: closeChroot' && _messageFAIL

    cd "$functionEntryPWD"
    echo
    echo '          PASS'
    echo '          good: success: _upgrade_report'
    echo
}



_upgrade_core() {
	local functionEntryPWD
	functionEntryPWD="$PWD"

    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

    _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest pull'
    _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest submodule update --recursive'
    _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; ./ubiquitous_bash.sh _upgrade'

    ! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    cd "$functionEntryPWD"
}

# Normally does nothing: MSWindows installers are usually only copied with custom ubdist/OS derivatives specifically used for bootstrapping MSWindows... and usually those derivatives custom procedures will effect this update, etc, already.
_upgrade_installers() {
    local functionEntryPWD
    functionEntryPWD="$PWD"
    
    echo
    echo 'init: _upgrade_installers'
    echo

	! _messagePlain_probe_cmd _openChRoot && _messagePlain_bad 'fail: openChroot' && _messageFAIL

    if _chroot sudo -n -u user bash -c '[[ -e /home/user/core/installations/pumpCompanion.exe ]] || [[ -e /home/user/core/installations/extIface.exe ]] || [[ -e /home/user/core/installations/ubDistBuild.exe ]]'
    then

        # https://unix.stackexchange.com/questions/486760/is-it-possible-to-allow-multiple-ssh-host-keys-for-the-same-ip
        _messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest pull'
        _messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest submodule update --recursive'

        #_wget_githubRelease "mirage335-gizmos/pumpCompanion" "internal" "pumpCompanion.exe"
        #sudo -n mv -f pumpCompanion.exe "$globalVirtFS"/home/user/core/installations/
        _chroot sudo -n -u user bash -c '[[ -e /home/user/core/installations/pumpCompanion.exe ]]' && _messagePlain_probe_cmd _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; ./ubiquitous_bash.sh _upgrade_binary_GitHubRelease mirage335-gizmos/pumpCompanion pumpCompanion.exe /home/user/core/installations'
        

        #_wget_githubRelease "mirage335-colossus/extendedInterface" "internal" "extIface.exe"
        #sudo -n mv -f extIface.exe "$globalVirtFS"/home/user/core/installations/
        _chroot sudo -n -u user bash -c '[[ -e /home/user/core/installations/extIface.exe ]]' && _messagePlain_probe_cmd _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; ./ubiquitous_bash.sh _upgrade_binary_GitHubRelease mirage335-colossus/extendedInterface extIface.exe /home/user/core/installations'
        
        
        #_wget_githubRelease "soaringDistributions/ubDistBuild" "internal" "ubDistBuild.exe"
        #sudo -n mv -f ubDistBuild.exe "$globalVirtFS"/home/user/core/installations/
        _chroot sudo -n -u user bash -c '[[ -e /home/user/core/installations/ubDistBuild.exe ]]' && _messagePlain_probe_cmd _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; ./ubiquitous_bash.sh _upgrade_binary_GitHubRelease soaringDistributions/ubDistBuild ubDistBuild.exe /home/user/core/installations'

    fi
	
	! _messagePlain_probe_cmd _closeChRoot && _messagePlain_bad 'fail: closeChroot' && _messageFAIL

    cd "$functionEntryPWD"
    echo
    echo '          PASS'
    echo '          good: success: _upgrade_installers'
    echo
}


_upgrade_apt() {
    local functionEntryPWD
    functionEntryPWD="$PWD"
    
    echo
    echo 'init: _upgrade_apt'
    echo
    
	# ATTRIBUTION-AI: ChatGPT o1-preview 2024-11-20 .
    _messagePlain_probe sudo -n tee /etc/apt/apt.conf.d/99autoremove-recommends
	echo 'APT::AutoRemove::RecommendsImportant "true";
APT::AutoRemove::SuggestsImportant "true";' | sudo -n tee /etc/apt/apt.conf.d/99autoremove-recommends > /dev/null
    
    # https://www.commandinline.com/cheat-sheet/apt/?utm_source=chatgpt.com
    _chroot env DEBIAN_FRONTEND=noninteractive apt-get -y update
    _chroot env DEBIAN_FRONTEND=noninteractive apt-get --install-recommends -y upgrade
    _chroot env DEBIAN_FRONTEND=noninteractive apt --install-recommends -y upgrade
    _chroot env DEBIAN_FRONTEND=noninteractive apt --install-recommends -y full-upgrade




    cd "$functionEntryPWD"
    echo
    echo '          PASS'
    echo '          good: success: _upgrade_apt: '"$1"
    echo
}





# ATTENTION: Upgrade kernel functions are similar to 'custom' functions, and WILL replace the existing kernel.

_upgrade_kernel_remove() {
    _messageNormal 'init: _upgrade_kernel_remove'
    
    
    # Formal naming convention is [-distllc,][-lts,-mainline,][-desktop,-server,] . ONLY requirement is dotglob removal of all except server OR all purpose lts .
    
    ##'linux-headers*desktop'
	#_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*desktop'
	##'linux-headers*mainline'
	#_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*mainline'
	##'linux-headers*lts'
	#_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*lts'


	#_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*'


    _messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*'
    _messagePlain_probe_cmd _chroot apt-get -y purge 'linux-image*'
    #_messagePlain_probe_cmd _chroot apt-get autoremove -y --purge

    _messagePlain_probe_cmd _chroot dpkg --get-selections | grep 'linux-image'

	
	#_messagePlain_probe_cmd _chroot apt-get -y install 'linux-headers-amd64'


    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _upgrade_kernel_remove'
}

# WARNING: May be untested.
_upgrade_kernel_kernel-dpkg_sequence() {
    #sudo -n dpkg -i "$1"
    _messagePlain_probe_cmd sudo -n dpkg -i "$1"
    [[ "$?" != "0" ]] && _messagePlain_bad 'fail: dpkg -i '"$1" && echo > ./FAIL && _messageFAIL

    return 0
}
_upgrade_kernel_kernel_sequence() {
    local functionEntryPWD
    functionEntryPWD="$PWD"

    _messageNormal 'init: _upgrade_kernel_kernel_sequence: '"$1"' '
    
    _start

    _messagePlain_probe_cmd cp -f /home/user/core/installations/kernel_linux/"$1" "$safeTmp"/kernel_package.tar.gz

    _messagePlain_probe_cmd cd "$safeTmp"
    _messagePlain_probe_cmd tar xvf "$safeTmp"/kernel_package.tar.gz

	#_messagePlain_probe_cmd find "$safeTmp" -iname '*.deb' -exec echo {} \;
    _messagePlain_probe_cmd find "$safeTmp" -iname '*headers*.deb' -exec "$scriptAbsoluteLocation" _upgrade_kernel_kernel-dpkg_sequence {} \;
    _messagePlain_probe_cmd ls -l /usr/src/*
    _messagePlain_probe_cmd find "$safeTmp" -iname '*libc*.deb' -exec "$scriptAbsoluteLocation" _upgrade_kernel_kernel-dpkg_sequence {} \;
    _messagePlain_probe_cmd find "$safeTmp" -iname '*image*.deb' -exec "$scriptAbsoluteLocation" _upgrade_kernel_kernel-dpkg_sequence {} \;
    _messagePlain_probe_cmd find "$safeTmp" -iname '*.deb' -exec "$scriptAbsoluteLocation" _upgrade_kernel_kernel-dpkg_sequence {} \;

    [[ -e "$safeTmp"/FAIL ]] && _messagePlain_bad 'fail: _upgrade_kernel_kernel_sequence: '"$1" && _messageFAIL

    _messagePlain_probe_cmd sudo -n apt-get -y install 'linux-headers-amd64'

	! _messagePlain_probe_cmd sudo -n apt-get -y install -f && _messagePlain_bad 'fail: apt-get -y install -f' && _messageFAIL
    
    cd "$functionEntryPWD"
    
    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _upgrade_kernel_kernel_sequence: '"$1"
    _stop
}
_upgrade_kernel_kernel() {
	echo
    echo 'init: _upgrade_kernel_kernel: '"$1"
    echo
    
    local functionEntryPWD
	functionEntryPWD="$PWD"
	
	! _messagePlain_probe_cmd "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	_messagePlain_probe_cmd _upgrade_kernel_remove

    #linux-lts-amd64-debian.tar.gz
    #linux-mainline-amd64-debian.tar.gz
    ##linux-lts-server-amd64-debian.tar.gz
    #linux-mainline-server-amd64-debian.tar.gz
    local currentKernelPackage
    currentKernelPackage="$1"
    _messagePlain_probe_var currentKernelPackage

    # https://unix.stackexchange.com/questions/486760/is-it-possible-to-allow-multiple-ssh-host-keys-for-the-same-ip
    _messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest pull'
    _messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest submodule update --recursive'
    ! _messagePlain_probe_cmd _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistFetch ; ./ubiquitous_bash.sh _upgrade_binary_GitHubRelease soaringDistributions/mirage335KernelBuild '"$currentKernelPackage"' /home/user/core/installations/kernel_linux' && _messagePlain_bad 'fail: _upgrade_binary_GitHubRelease: '"$currentKernelPackage" && _messageFAIL
    
	_messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest pull'
    _messagePlain_probe_cmd _chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest submodule update --recursive'
    ! _messagePlain_probe_cmd _chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild ; ./ubiquitous_bash.sh _upgrade_kernel_kernel_sequence '"$currentKernelPackage" && _messagePlain_bad 'fail: _upgrade_kernel_kernel_sequence: '"$currentKernelPackage" && _messageFAIL
    

	
	! _messagePlain_probe_cmd "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	cd "$functionEntryPWD"
    echo
    echo '          PASS'
    echo '          good: success: _upgrade_kernel_kernel: '"$1"
    echo
}
_upgrade_kernel_server() {
	! _messagePlain_probe_cmd "$scriptAbsoluteLocation" _upgrade_kernel_kernel linux-mainline-server-amd64-debian.tar.gz && _messagePlain_bad 'fail: _upgrade_kernel_server' && _messageFAIL
    echo '          good: success: _upgrade_kernel_server'
    echo
}
_upgrade_kernel_mainline_server() {
    _upgrade_kernel_server
}

_upgrade_kernel_lts() {
	! _messagePlain_probe_cmd "$scriptAbsoluteLocation" _upgrade_kernel_kernel linux-lts-amd64-debian.tar.gz && _messagePlain_bad 'fail: _upgrade_kernel_lts' && _messageFAIL
    echo '          good: success: _upgrade_kernel_lts'
    echo
}

_upgrade_kernel() {
	_upgrade_kernel_lts
}







