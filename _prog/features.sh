
_backup_restore_vm-wsl2-rsync-exclude() {
    local currentSource
    local currentDestination

    currentSource="$1"
    currentDestination="$2"

    if [[ "$currentSource" == "" ]] || [[ "$currentSource" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: source'
        return 1
    fi
    if [[ "$currentDestination" == "" ]] || [[ "$currentDestination" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: destination'
        return 1
    fi

    if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

    [[ "$currentSource" != *"/." ]] && currentSource="$1"/.
    [[ "$currentDestination" != *"/." ]] && currentDestination="$2"/.


	if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

	_messagePlain_probe_cmd rsync -ax --delete --exclude ".Xauthority" --exclude ".bash_history" --exclude ".bash_logout" --exclude ".cache" --exclude ".face" --exclude ".face.icon" --exclude ".gEDA" --exclude ".gcloud" --exclude ".gnome" --exclude ".kde.bak" --exclude ".nix-channels" --exclude ".nix-defexpr" --exclude ".nix-profile" --exclude ".python_history" --exclude ".pythonrc" --exclude ".sudo_as_admin_successful" --exclude ".terraform.d" --exclude ".xsession-errors" --exclude "Downloads" --exclude "___quick" --exclude "_unix_renice_execDaemon.log" --exclude "core" --exclude "package_kde.tar.xz" --exclude "project" --exclude "rottenScript.sh" --exclude "ubDistBuild" --exclude "ubDistFetch" --exclude ".config" --exclude ".kde" --exclude ".local" --exclude ".xournal" --exclude ".license_package_kde" --exclude ".bash_profile" --exclude ".bashrc" --exclude ".config" --exclude ".gitconfig" --exclude ".inputrc" --exclude ".lesshst" --exclude ".octave_hist" --exclude ".octaverc" --exclude ".profile" --exclude ".ubcore" --exclude ".ubcorerc_pythonrc.py" --exclude ".ubcorerc-gnuoctave.m" --exclude ".viminfo" --exclude ".wget-hsts" --exclude "bin" "$currentSource" "$currentDestination"
}
_backup_restore_vm-wsl2-rsync-basic() {
    local currentSource
    local currentDestination

    currentSource="$1"
    currentDestination="$2"

    if [[ "$currentSource" == "" ]] || [[ "$currentSource" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: source'
        return 1
    fi
    if [[ "$currentDestination" == "" ]] || [[ "$currentDestination" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: destination'
        return 1
    fi

    if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

    [[ "$currentSource" != *"/." ]] && currentSource="$1"/.
    [[ "$currentDestination" != *"/." ]] && currentDestination="$2"/.


	if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

	_messagePlain_probe_cmd rsync -ax --delete "$currentSource" "$currentDestination"
}

_backup_vm-wsl2() {
   ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && return 1

    _messagePlain_request 'request: Backup is on a limited best effort basis only.'
    echo 'wait: 5seconds: Ctrl+c repeatedly to cancel'
    echo "If you don't know what this means, and you haven't extensively used 'ubdist' through WSL, then you probably have nothing to worry about."
    echo "Otherwise - you should copy your data out of WSL2 before upgrading or uninstalling."
	local currentIteration
	for currentIteration in $(seq 1 5)
	do
		sleep 1
	done
	echo 'NOT cancelled.'
    echo
    echo

    if ! mkdir -p /cygdrive/c/core/infrastructure/uwsl-h-b-"$1" || [[ ! -e /cygdrive/c/core/infrastructure/uwsl-h-b-"$1" ]]
    then
        _messagePlain_bad 'fail: mkdir: /cygdrive/c/core/infrastructure/uwsl-h-b'-"$1"
        return 1
    fi

    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")
    local currentBackupLocationUNIX
    currentBackupLocationUNIX=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"
    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")

    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-exclude /home/user/. "'""$currentBackupLocationMSW""'"
    echo

    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX"/.ssh)
    #wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-basic /home/user/.ssh/. "'""$currentBackupLocationMSW""'"
}

_restore_vm-wsl2() {
    ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && return 1

    _messagePlain_request 'request: Restore is on a limited best effort basis only.'
    echo "If you don't know what this means, and you haven't extensively used 'ubdist' through WSL, then you probably have nothing to worry about."
    echo "Otherwise - you should copy your data out of WSL2 before upgrading or uninstalling."
    echo
    echo

    if ! mkdir -p /cygdrive/c/core/infrastructure/uwsl-h-b-"$1" || [[ ! -e /cygdrive/c/core/infrastructure/uwsl-h-b-"$1" ]]
    then
        _messagePlain_bad 'fail: mkdir: /cygdrive/c/core/infrastructure/uwsl-h-b'-"$1"
        return 1
    fi

    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")
    local currentBackupLocationUNIX
    currentBackupLocationUNIX=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"
    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")

    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-exclude "'""$currentBackupLocationMSW""'" /home/user/.
    echo
    
    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX"/.ssh)
    #wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-basic "'""$currentBackupLocationMSW""'" /home/user/.ssh/.
}


# End user function .
_setup_vm-wsl2_sequence() {
    _start
    local functionEntryPWD
    functionEntryPWD="$PWD"

    ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && _stop 1

    if [[ -e "$scriptLocal"/package_rootfs.tar.flx ]] && [[ ! -e "$scriptLocal"/package_rootfs.tar ]]
    then
        cat "$scriptLocal"/package_rootfs.tar.flx | lz4 -d -c > "$scriptLocal"/package_rootfs.tar
        rm -f "$scriptLocal"/package_rootfs.tar.flx
    fi

    [[ ! -e "$scriptLocal"/package_rootfs.tar ]] && _messagePlain_bad 'bad: missing: package_rootfs.tar' && _messageFAIL && _stop 1


    mkdir -p '/cygdrive/c/core/infrastructure/ubdist_wsl'
    _userMSW _messagePlain_probe wsl --import ubdist '/cygdrive/c/core/infrastructure/ubdist_wsl' "$scriptLocal"/package_rootfs.tar --version 2
    _userMSW wsl --import ubdist '/cygdrive/c/core/infrastructure/ubdist_wsl' "$scriptLocal"/package_rootfs.tar --version 2

    _messagePlain_probe wsl --set-default ubdist
    wsl --set-default ubdist

    #wsl --unregister ubdist

    cd "$functionEntryPWD"
    _stop
}
_setup_vm-wsl2() {
    "$scriptAbsoluteLocation" _setup_vm-wsl2_sequence "$@"
}
_setup_vm-wsl() {
    _setup_vm-wsl2 "$@"
}



# End user function .
_install_wsl2() {
    _setup_wsl2 "$@"
}
_install_wsl() {
    _install_wsl2 "$@"
}

# End user function .
_install_vm-wsl2() {
    _setup_vm-wsl2 "$@"
}
_install_vm-wsl() {
    _install_vm-wsl2 "$@"
}







# DANGER: Not adequately proven. No production use. May not be tested.
# Not very practical. Debian install process asks for a password. Breaks automatic install, and doesn't prevent 'wsl -u root -d Debian' anyway.
# ATTENTION: Use case would be bootstrapping - creating a Linux installation capable of '_chroot' to do '_convert_rootfs' from MSW .
# WARNING: No production use.
_install_chroot() {
    _start
    local functionEntryPWD
    functionEntryPWD="$PWD"

    # https://stackoverflow.com/questions/76404375/wsl2-debian-automatic-unattended-re-installation
    # https://www.sindastra.de/p/679/no-sudo-password-in-wsl

    _messagePlain_request 'request: enter to continue'
    read > /dev/null 2>&1

    #_messagePlain_probe wsl --install -d Debian
    #wsl --install -d Debian
    #wsl --install -d Debian --no-launch

    #echo "`whoami` ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/`whoami` && sudo chmod 0440 /etc/sudoers.d/`whoami`
    #wsl -u root -d Debian

    #wsl --unregister Debian

    (echo 'user' ; echo pass ; echo pass) | wsl --install -d Debian



    cd "$functionEntryPWD"
    _stop
}






# DANGER: Untested.
# BROKEN
_install_chroot-appx() {
    _start
    local functionEntryPWD
    functionEntryPWD="$PWD"

    [[ ! -e "$scriptLocal"/Debian.AppxBundle ]] && curl -L -o "$scriptLocal"/Debian.AppxBundle https://aka.ms/wsl-debian-gnulinux
    
    cp -f "$scriptLocal"/Debian.AppxBundle "$scriptLocal"/Debian.AppxBundle.zip
    unzip "$scriptLocal"/Debian.AppxBundle.zip -d "$safeTmp"/ubDistBuild
    rm -f "$scriptLocal"/Debian.AppxBundle.zip

    _messagePlain_request 'request: enter to continue'
    read > /dev/null 2>&1

    
    #_messagePlain_probe wsl --install -d Debian
    #wsl --install -d Debian

    _userMSW _messagePlain_probe _powershell Add-AppxPackage "$safeTmp"/ubDistBuild/DistroLauncher-Appx_1.12.2.0_x64.appx
    _userMSW _powershell Add-AppxPackage "$safeTmp"/ubDistBuild/DistroLauncher-Appx_1.12.2.0_x64.appx


    cd "$functionEntryPWD"
    _stop
}


# DANGER: BROKEN
_install_vm-wsl2-from_VHDX() {
    [[ ! -e "$scriptLocal"/vm.vhdx ]] && _messagePlain_bad 'bad: missing: vm.vhdx' && _messageFAIL && _stop 1

    #_userMSW _messagePlain_probe wsl --import-in-place ubdist "$scriptLocal"/vm.vhdx --version 2
    #_userMSW wsl --import-in-place ubdist "$scriptLocal"/vm.vhdx --version 2

    _messagePlain_probe wsl --set-default ubdist
    wsl --set-default ubdist

    # https://superuser.com/questions/1667969/create-wsl2-instance-from-vhdx
}
_install_vm-wsl-from_VHDX() {
    _install_vm-wsl2 "$@"
}





