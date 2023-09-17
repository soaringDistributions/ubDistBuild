




_get_extract_ubDistBuild() {
	# https://unix.stackexchange.com/questions/85194/how-to-download-an-archive-and-extract-it-without-saving-the-archive-to-disk
	#pv | xz -d | tar xv --overwrite "$@"

	#xz -d | tar xv --overwrite "$@"

	lz4 -d -c | tar xv --overwrite "$@"
}



_get_vmImg_ubDistBuild_sequence() {
	_messageNormal 'init: _get_vmImg'

	local releaseLabel
	releaseLabel="internal"
	[[ "$1" != "" ]] && releaseLabel="$1"
	[[ "$1" == "latest" ]] && releaseLabel=
	
	local functionEntryPWD
	functionEntryPWD="$PWD"
	
	
	mkdir -p "$scriptLocal"
	
	# Only extracted vm img.
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*
	
	if [[ -e "$scriptLocal"/vm.img ]]
	then
		_messagePlain_good 'good: exists: vm.img'
		return 0
	fi
	
	if [[ -e "$scriptLocal"/ops.sh ]]
	then
		mv -n "$scriptLocal"/ops.sh "$scriptLocal"/ops.sh.bak
	fi
	
	cd "$scriptLocal"
	mkdir -p "$scriptLocal"
	cd "$scriptLocal"
	export MANDATORY_HASH="true"
	_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "package_image.tar.flx" | _get_extract_ubDistBuild
	[[ "$?" != "0" ]] && _messageFAIL
	export MANDATORY_HASH=
	unset MANDATORY_HASH



	_messagePlain_nominal '_get_vmImg: hash'

	if [[ -e "$scriptLocal"/ops.sh ]]
	then
		mv -f "$scriptLocal"/ops.sh "$scriptLocal"/ops.sh.ref
		rm -f "$scriptLocal"/ops.sh
	fi
	
	local currentHash
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 3 | tail -n 1)
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	local currentFilePath
	currentFilePath="$scriptLocal"/vm.img
	local currentHashLocal
	if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        currentHashLocal=$(cat "$currentFilePath" | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
    else
        currentHashLocal=$(cat "$currentFilePath" | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
    fi

	_messagePlain_probe_var currentHash
	_messagePlain_probe_var currentHashLocal
	[[ "$currentHash" != "$currentHashLocal" ]] && _messageFAIL

	_messagePlain_good 'done: hash'

	cd "$functionEntryPWD"
}
_get_vmImg_ubDistBuild() {
	"$scriptAbsoluteLocation" _get_vmImg_ubDistBuild_sequence "$@"
}

_get_vmImg_ubDistBuild-live_sequence() {
	_messageNormal 'init: _get_vmImg-live'
	
	local releaseLabel
	releaseLabel="internal"
	[[ "$1" != "" ]] && releaseLabel="$1"
	[[ "$1" == "latest" ]] && releaseLabel=

	local functionEntryPWD
	functionEntryPWD="$PWD"
	
	
	_messagePlain_nominal '_get_vmImg-live: download'

	mkdir -p "$scriptLocal"
	cd "$scriptLocal"
	export MANDATORY_HASH="true"
	_wget_githubRelease_join "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso"
	[[ "$?" != "0" ]] && _messageFAIL
	export MANDATORY_HASH=
	unset MANDATORY_HASH



	_messagePlain_nominal '_get_vmImg: hash'

	
	local currentHash
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 15 | tail -n 1)
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	local currentFilePath
	currentFilePath="$scriptLocal"/vm-live.iso
	local currentHashLocal
	if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        currentHashLocal=$(cat "$currentFilePath" | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
    else
        currentHashLocal=$(cat "$currentFilePath" | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
    fi

	_messagePlain_probe_var currentHash
	_messagePlain_probe_var currentHashLocal
	[[ "$currentHash" != "$currentHashLocal" ]] && _messageFAIL

	_messagePlain_good 'done: hash'

	cd "$functionEntryPWD"
}
_get_vmImg_ubDistBuild-live() {
	"$scriptAbsoluteLocation" _get_vmImg_ubDistBuild-live_sequence "$@"
}

# DANGER: MANDATORY_HASH==true
_get_vmImg_ubDistBuild-rootfs_sequence() {
	_messageNormal 'init: _get_vmImg-rootfs'
	
	local releaseLabel
	releaseLabel="internal"
	[[ "$1" != "" ]] && releaseLabel="$1"
	[[ "$1" == "latest" ]] && releaseLabel=

	local functionEntryPWD
	functionEntryPWD="$PWD"
	
	_messagePlain_nominal '_get_vmImg-rootfs: download'

	mkdir -p "$scriptLocal"
	cd "$scriptLocal"
	export MANDATORY_HASH="true"
	_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "package_rootfs.tar.flx" | lz4 -d -c > ./package_rootfs.tar
	[[ "$?" != "0" ]] && _messageFAIL
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	_messagePlain_good 'done: download'



	_messagePlain_nominal '_get_vmImg: hash'

	
	local currentHash
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 9 | tail -n 1)
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	local currentFilePath
	currentFilePath="$scriptLocal"/package_rootfs.tar
	local currentHashLocal
	if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        currentHashLocal=$(cat "$currentFilePath" | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
    else
        currentHashLocal=$(cat "$currentFilePath" | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
    fi

	_messagePlain_probe_var currentHash
	_messagePlain_probe_var currentHashLocal
	[[ "$currentHash" != "$currentHashLocal" ]] && _messageFAIL

	_messagePlain_good 'done: hash'

	cd "$functionEntryPWD"
}
# DANGER: MANDATORY_HASH==true
_get_vmImg_ubDistBuild-rootfs() {
	"$scriptAbsoluteLocation" _get_vmImg_ubDistBuild-rootfs_sequence "$@"
}




_get_core_ubDistFetch_sequence() {
	_messageNormal 'init: _get_core'
	
	local functionEntryPWD
	functionEntryPWD="$PWD"
	
	
	mkdir -p "$scriptLocal"
	
	# Only newest core .
	rm -f "$scriptLocal"/core.tar.xz > /dev/null 2>&1
	
	if [[ -e "$scriptLocal"/core.tar.xz ]]
	then
		_messagePlain_good 'good: exists: core.tar.xz'
		return 0
	fi
	
	if [[ -e "$scriptLocal"/ops.sh ]]
	then
		mv -n "$scriptLocal"/ops.sh "$scriptLocal"/ops.sh.bak
	fi
	
	cd "$scriptLocal"
	
	
	#if ( [[ -e /rclone.conf ]] && grep distLLC_release /rclone.conf ) || ( [[ -e "$scriptLocal"/rclone_limited/rclone.conf ]] && grep distLLC_release "$scriptLocal"/rclone_limited/rclone.conf )
	#then
		## https://rclone.org/commands/rclone_cat/
		#_rclone_limited cat distLLC_release:/ubDistFetch/core.tar.xz | _get_extract_ubDistBuild
		#[[ "$?" != "0" ]] && _messageFAIL
	#fi
	
	# https://unix.stackexchange.com/questions/85194/how-to-download-an-archive-and-extract-it-without-saving-the-archive-to-disk
	_messagePlain_probe 'wget'
	wget --user u298813-sub10 --password OJgZTe0yNilixhRy 'https://u298813-sub10.your-storagebox.de/zSpecial/build_ubDistFetch/dump/core.tar.xz'
	[[ "$?" != "0" ]] && _messageFAIL
	
	cd "$functionEntryPWD"
}
_get_core_ubDistFetch() {
	"$scriptAbsoluteLocation" _get_core_ubDistFetch_sequence "$@"
}


