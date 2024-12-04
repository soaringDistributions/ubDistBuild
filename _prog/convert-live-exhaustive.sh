

_live_procedure_exhaustive-vmImg() {
    sudo -n mksquashfs "$safeTmp"/NOTmounted "$scriptLocal"/livefs/image/live/filesystem.squashfs -b 262144 -no-xattrs -noI -noX -comp lzo -Xalgorithm lzo1x_1
}
_live_procedure_exhaustive-rootfs() {
    if [[ "$currentLiveExhaustive_rootfs" != "false" ]]
    then
        sudo -n mksquashfs "$safeTmp"/NOTmounted "$scriptLocal"/livefs/image/live/filesystem.squashfs -b 262144 -no-xattrs -noI -noX -comp lzo -Xalgorithm lzo1x_1
        return
    else
        return 0
    fi
}
_live_procedure_exhaustive-includeConfig() {
    _live_procedure_exhaustive-includeConfig-message() {
        [[ ! -e "$scriptLocal"/include-exhaustive/"$1" ]] && _messagePlain_warn 'warn: missing: '"$1"
    }
    _live_procedure_exhaustive-includeConfig-message extIface.exe
    _live_procedure_exhaustive-includeConfig-message ubDistBuild.exe
	
    _live_procedure_exhaustive-includeConfig-message pumpCompanion.exe

    # https://ninite.com/7zip-ccleaner-gimp-inkscape-klitecodecs-libreoffice-notepadplusplus-vlc-winamp-zoom/
    #_live_procedure_exhaustive-includeConfig-message 'Ninite 7Zip CCleaner GIMP Inkscape KLite Codecs Installer.exe'

    # https://ninite.com/7zip-ccleaner-discord-firefox-gimp-inkscape-klitecodecs-libreoffice-notepadplusplus-vlc-winamp-zoom/
    #_live_procedure_exhaustive-includeConfig-message 'Ninite 7Zip CCleaner Discord Firefox GIMP Inkscape Installer.exe'
}
_live_procedure_exhaustive-include() {
    if [[ "$currentLiveExhaustive_include" != "false" ]]
    then
        mkdir -p "$scriptLocal"/include-exhaustive
        
        _live_procedure_exhaustive-includeConfig

        cp -r "$scriptLocal"/include-exhaustive/* "$scriptLocal"/livefs/image/
        return
    else
        return 0
    fi
}
_live_procedure_exhaustive-pattern() {
    if [[ "$currentLiveExhaustive_pattern" != "false" ]]
    then
        _pattern_recovery_write "$scriptLocal"/livefs/image/live/pattern.img 32768
        return
    else
        return 0
    fi
}
_live_sequence_exhaustive() {
    _start

    mkdir -p "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local
    
    _messagePlain_nominal 'copy: vm.img'
    mkdir -p "$safeTmp"/NOTmounted
    #mkdir -p "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local
    if ! cp "$scriptLocal"/vm.img "$safeTmp"/NOTmounted/vm.img
    #if ! cp "$scriptLocal"/vm.img "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local/vm.img
    then
        _messagePlain_bad 'bad: missing: vm.img'
        _messageFAIL
        _stop 1
        return 1
    fi

    mkdir -p "$scriptLocal"/livefs/image/live

    _live_procedure_exhaustive-vmImg "$@"
	du -sh "$scriptLocal"/livefs/image/live/filesystem.squashfs
    rm -f "$safeTmp"/NOTmounted/vm.img
    rm -f "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local/vm.img


    _messagePlain_nominal 'copy: package_rootfs.tar'
    mkdir -p "$safeTmp"/NOTmounted
    #mkdir -p "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local
    if ! cp "$scriptLocal"/package_rootfs.tar "$safeTmp"/NOTmounted/package_rootfs.tar
    #if ! cp "$scriptLocal"/package_rootfs.tar "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local/package_rootfs.tar
    then
        _messagePlain_bad 'bad: missing: package_rootfs.tar'
        _messageFAIL
        _stop 1
        return 1
    fi

    mkdir -p "$scriptLocal"/livefs/image/live

    _live_procedure_exhaustive-rootfs "$@"
	du -sh "$scriptLocal"/livefs/image/live/filesystem.squashfs
    rm -f "$safeTmp"/NOTmounted/package_rootfs.tar
    rm -f "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local/package_rootfs.tar

    mkdir -p "$scriptLocal"/livefs/image/live

    _live_procedure_exhaustive-rootfs "$@"
	du -sh "$scriptLocal"/livefs/image/live/filesystem.squashfs
    rm -f "$safeTmp"/NOTmounted/package_rootfs.tar
    rm -f "$safeTmp"/NOTmounted/home/user/ubDistBuild/_local/package_rootfs.tar



    _safeRMR "$safeTmp"/NOTmounted
    if [[ -e "$safeTmp"/NOTmounted ]]
    then
        _messagePlain_bad 'fail: _safeRMR: "$safeTmp"/NOTmounted'
        _messageFAIL
        _stop 1
        return 1
    fi

    _live_procedure_exhaustive-include

    # ATTENTION: Would prefer to append to ISO, but the implications of doing so have not been thoroughly tested.
    _live_procedure_exhaustive-pattern

    _stop
}

_convert-live-exhaustive() {
	_messageNormal '_convert: vm-live-exhaustive.iso'

    if [[ ! -e "$scriptLocal"/vm.img ]]
    then
        _messagePlain_bad 'bad: missing: vm.img'
        _messageFAIL
        _stop 1
        return 1
    fi

    if [[ ! -e "$scriptLocal"/package_rootfs.tar ]]
    then
        _messagePlain_bad 'bad: missing: package_rootfs.tar'
        _messageFAIL
        _stop 1
        return 1
    fi

    # Should have already called '_live_sequence_in' before '_convert-live-exhaustive'.
    # Copy of 'vm-live.iso' is not included because obviously this 'exhaustive' Live ISO already is such a bootable ISO .
    #if [[ ! -e "$scriptLocal"/vm-live.iso ]]
    #then
        #_messagePlain_bad 'bad: missing: vm-live.iso'
        #_messagePlain_request 'request: _convert-live (adds desirable changes for slow-throughput slow-seek and improves revert capability)'
        #_messageFAIL
        #_stop 1
        #return 1
	#fi

    _live_procedure_exhaustive-includeConfig

    rm -f "$scriptLocal"/_hash-exhaustive--ubdist.txt
    rm -f "$scriptLocal"/vm-live.iso
	
	if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"
	then
		_stop 1
	fi

    if ! "$scriptAbsoluteLocation" _live_sequence_exhaustive "$@"
    then
        _messageFAIL
        _stop 1
    fi
	
	[[ "$current_diskConstrained" == "true" ]] && rm -f "$scriptLocal"/vm.img
	
	if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"
	then
		_stop 1
	fi

    rm -f "$scriptLocal"/_hash-exhaustive--ubdist.txt
    _hash_file exhaustive--ubdist exhaustive--vm-live.iso "$scriptLocal"/vm-live.iso cat
    
	
	_safeRMR "$scriptLocal"/livefs
}

_convert-live-exhaustive-BDXL() {
    export currentLiveExhaustive_rootfs="true"
    export currentLiveExhaustive_include="true"
    export currentLiveExhaustive_pattern="true"
    
    _convert-live-exhaustive "$@"
}

_convert-live-exhaustive-BDDL() {
    export currentLiveExhaustive_rootfs="false"
    export currentLiveExhaustive_include="false"
    export currentLiveExhaustive_pattern="false"
   
    _convert-live-exhaustive "$@"
}


