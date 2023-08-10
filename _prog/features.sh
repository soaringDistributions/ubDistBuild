


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





