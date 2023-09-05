
_live_sequence_exhaustive() {
    _start
    
    _messagePlain_nominal 'copy: vm.img'
    mkdir -p "$safeTmp"/NOTmounted
    if ! cp "$scriptLocal"/vm.img "$safeTmp"/NOTmounted/vm.img
    then
        _messageFAIL
        _stop 1
    fi
    if ! cp "$scriptLocal"/package_rootfs.tar "$safeTmp"/NOTmounted/package_rootfs.tar
    then
        _messageFAIL
        _stop 1
    fi
    
    sudo -n mksquashfs "$safeTmp"/NOTmounted "$scriptLocal"/livefs/image/live/filesystem.squashfs -b 262144 -no-xattrs -noI -noX -comp lzo -Xalgorithm lzo1x_1
	du -sh "$scriptLocal"/livefs/image/live/filesystem.squashfs

    _stop
}

_convert-live-exhaustive() {
	_messageNormal '_convert: vm-live-exhaustive.iso'

    if [[ ! -e "$scriptLocal"/package_rootfs.tar ]]
    then
        _messagePlain_bad 'bad: missing: package_rootfs.tar'
        _messageFAIL
        _stop 1
        return 1
    fi

    if [[ ! -e "$scriptLocal"/vm-live.iso ]]
    then
        _messagePlain_bad 'bad: missing: vm-live.iso'
        _messagePlain_request 'request: _convert-live (adds desirable changes for slow-throughput slow-seek and improves revert capability)'
        _messageFAIL
        _stop 1
        return 1
	fi

    if ! "$scriptAbsoluteLocation" _live_sequence_exhaustive "$@"
    then
        _messageFAIL
        _stop 1
    fi
	
	if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"
	then
		_stop 1
	fi
	
	[[ "$current_diskConstrained" == "true" ]] && rm -f "$scriptLocal"/vm.img
	
	if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"
	then
		_stop 1
	fi
	
	_safeRMR "$scriptLocal"/livefs
}




