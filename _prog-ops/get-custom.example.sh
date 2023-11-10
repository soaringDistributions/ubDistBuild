




_get_extract_ubDistBuild-tar() {
	# https://unix.stackexchange.com/questions/85194/how-to-download-an-archive-and-extract-it-without-saving-the-archive-to-disk
	#pv | xz -d | tar xv --overwrite "$@"

	#xz -d | tar xv --overwrite "$@"

	#lz4 -d -c | tar xv --overwrite "$@"
	
	lz4 -d -c | tar "$@"
}

_get_extract_ubDistBuild() {
	_get_extract_ubDistBuild-tar xv --overwrite "$@"
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
	rm -f "$scriptLocal"/_get/package_image.tar.flx
	rm -f "$scriptLocal"/_get/package_image.tar.flx.part*
	
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
	mkdir -p "$scriptLocal"/_get
	cd "$scriptLocal"/_get
	rm -f "$scriptLocal"/_get/ops.sh
	export MANDATORY_HASH="true"
	local currentExitStatus
	if [[ "$3" == "" ]] # || [[ "$FORCE_AXEL" != "" ]]
	then
		_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "package_image.tar.flx" | _get_extract_ubDistBuild-tar xv --overwrite
		currentExitStatus="$?"
	else
		#_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "package_image.tar.flx" | _get_extract_ubDistBuild-tar --extract vm.img --to-stdout | _dd of="$3" bs=1M
		_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "package_image.tar.flx" | _get_extract_ubDistBuild-tar --extract ./vm.img --to-stdout | sudo -n dd of="$3" bs=1M status=progress
		currentExitStatus="$?"
	fi
	if [[ "$currentExitStatus" != "0" ]]
	then
		rm -f "$scriptLocal"/_get/ops.sh
		_messageFAIL
	fi
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	#if [[ "$3" == "" ]] || [[ "$FORCE_AXEL" != "" ]]
	#then
		#true
	#else
		#_messagePlain_good 'done: dd: '"$3"
		#_stop 0
		#return 0
	#fi
	
	
	_messagePlain_nominal '_get_vmImg: hash'
	
	if [[ "$FORCE_AXEL" != "" ]] && [[ -e "$scriptLocal"/ops.sh ]]
	then
		mv -f "$scriptLocal"/_get/ops.sh "$scriptLocal"/_get/ops.sh.ref
		rm -f "$scriptLocal"/_get/ops.sh
	fi
	
	local currentHash
	local currentHash_bytes
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	if [[ "$2" != "" ]]
	then
		currentHash="$2"
		currentHash_bytes=$( [[ "$currentFilePath" != "/dev"* ]] && wc -c "$currentFilePath" )
	fi
	if [[ "$currentHash" == "" ]] || [[ "$currentHash_bytes" == "" ]]
	then
		currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 3 | tail -n 1)
		currentHash_bytes=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 2 | tail -n 1 | sed 's/^.*count=$(bc <<< '"'"'//' | cut -f1 -d\  )
	fi
	( [[ "$currentHash" == "" ]] || [[ "$currentHash_bytes" == "" ]] ) && _messageFAIL
	export MANDATORY_HASH=
	unset MANDATORY_HASH

	local currentFilePath
	currentFilePath="$scriptLocal"/_get/vm.img
	[[ "$3" != "" ]] && currentFilePath="$3"
	local currentHashLocal
	if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
	then
		#currentHashLocal=$(cat "$currentFilePath" | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
		currentHashLocal=$(dd if="$currentFilePath" bs=1M count=$(bc <<< "$currentHash_bytes"' / 1048576') status=progress | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
	else
		#currentHashLocal=$(cat "$currentFilePath" | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
		currentHashLocal=$(dd if="$currentFilePath" bs=1M count=$(bc <<< "$currentHash_bytes"' / 1048576') status=progress | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
	fi
	
	_messagePlain_probe_var currentHash_bytes
	_messagePlain_probe_var currentHash
	_messagePlain_probe_var currentHashLocal
	[[ "$currentHash" != "$currentHashLocal" ]] && _messageFAIL
	
	_messagePlain_good 'done: hash'
	
	[[ "$3" == "" ]] && mv -f "$scriptLocal"/_get/vm.img "$scriptLocal"/vm.img
	#mv -f "$scriptLocal"/_get/* "$scriptLocal"/
	rmdir "$scriptLocal"/_get
	#_safeRMR "$scriptLocal"/_get
	
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
	if [[ "$3" == "" ]] # || [[ "$FORCE_AXEL" != "" ]]
	then
		_wget_githubRelease_join "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso"
		currentExitStatus="$?"
	else
		currentHash_bytes=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 14 | tail -n 1 | sed 's/^.*count=$(bc <<< '"'"'//' | cut -f1 -d\  )
		
		if ! [[ $(df --block-size=1000000 --output=avail "$tmpSelf" | tr -dc '0-9') -gt "3880" ]]
		then
			_messagePlain_bad 'bad: Detected <3.88GB disk free. Assuming TMPFS from booted LiveISO, insufficient unoccupied RAM.'
			_messageFAIL
		fi
		
		# CAUTION: Cannot write interrupted pipe to disc without default management, apparently.
		#  Outrunning the input by more than approximately one minute still seems to cause disc corruption. Possibly hardware specific.
		# ATTENTION: If no sparing area is set here, the assumption is that directly written discs are intended for immediate use rather than as an archival quality set for which longevity would definitely be essential..
		# CAUTION: No sparing area, defect management, is somewhat bad practice, relying exclusively on hash, and not ensuring good margin for readability.
		#  There IS some evidence that ancient (>30years) optical discs used without defect management have had minor corruption as a direct result.
		#   Weak areas may be a strong indication of factory contamination with corrosive material.
		#-force -blank
		#sudo -n dvd+rw-format -ssa=default "$3"
		#sudo -n dvd+rw-format -ssa=min "$3"
		#sudo -n dvd+rw-format -ssa=256m "$3"
		#sudo -n dvd+rw-format -ssa=none "$3"
		
		#_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso" | sudo -n wodim -v -sao dev="$3" tsize="$currentHash_bytes" -waiti -
		#-speed=256
		#-dvd-compat
		#-overburn
		#-use-the-force-luke=bufsize:2560m
		#pv -pterbTCB 1G
		#_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso" | sudo -n growisofs -speed=256 -dvd-compat -Z "$3"=/dev/stdin -use-the-force-luke=notray
		
		
		
		
		
		( _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso" | tee >(openssl dgst -whirlpool -binary | xxd -p -c 256 >> "$scriptLocal"/hash-download.txt) ; dd if=/dev/zero bs=2048 count=$(bc <<< '1000000000000 / 2048' ) ) | sudo -n growisofs -speed=2 -dvd-compat -Z "$3"=/dev/stdin -use-the-force-luke=notray -use-the-force-luke=spare:min -use-the-force-luke=bufsize:128m
		currentExitStatus="$?"
		
		
		
		# May be untested.
		# Theoretically, wodim may be usable with Cygwin/MSW . Unfortunately, defect management may not be available. In any case, 'growisofs' is definitely preferable whenever possible.
		#( _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso" | tee >(openssl dgst -whirlpool -binary | xxd -p -c 256 >> "$scriptLocal"/hash-download.txt) ; dd if=/dev/zero bs=2048 count=$(bc <<< '0 / 2048' ) ) | sudo -n wodim -v -sao fs=128m dev="$3" blank=session tsize="$currentHash_bytes" /dev/stdin
		#currentExitStatus="$?"
		
		
		
		
		
		#_wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-live.iso" | cat > /dev/null
		#currentExitStatus="$?"
		
		
		#growisofs -M /dev/dvd=/dev/zero
		#growisofs -M /dev/sr1=/dev/zero -use-the-force-luke=notray
	fi
	#[[ "$currentExitStatus" != "0" ]] && _messageFAIL
	if [[ "$currentExitStatus" != "0" ]]
	then
		echo "Exit status 1 may be normal if caused by  'No space left on device'  ."
	fi
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	
	
	
	_messagePlain_nominal '_get_vmImg: hash'
	
	
	local currentHash
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	if [[ "$2" != "" ]]
	then
		currentHash="$2"
		currentHash_bytes=$( [[ "$currentFilePath" != "/dev"* ]] && wc -c "$currentFilePath" )
	fi
	if [[ "$currentHash" == "" ]] || [[ "$currentHash_bytes" == "" ]]
	then
		currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 15 | tail -n 1)
		currentHash_bytes=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 14 | tail -n 1 | sed 's/^.*count=$(bc <<< '"'"'//' | cut -f1 -d\  )
	fi
	( [[ "$currentHash" == "" ]] || [[ "$currentHash_bytes" == "" ]] ) && _messageFAIL
	export MANDATORY_HASH=
	unset MANDATORY_HASH
	
	local currentFilePath
	currentFilePath="$scriptLocal"/vm-live.iso
	[[ "$3" != "" ]] && currentFilePath="$3"
	local currentHashLocal
	if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
	then
		#currentHashLocal=$(cat "$currentFilePath" | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
		currentHashLocal=$(dd if="$currentFilePath" bs=2048 count=$(bc <<< "$currentHash_bytes"' / 2048') status=progress | cat | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256)
	else
		#currentHashLocal=$(cat "$currentFilePath" | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
		currentHashLocal=$(dd if="$currentFilePath" bs=2048 count=$(bc <<< "$currentHash_bytes"' / 2048') status=progress | cat | openssl dgst -whirlpool -binary | xxd -p -c 256)
	fi
	
	_messagePlain_probe_var currentHash_bytes
	_messagePlain_probe_var currentHash
	_messagePlain_probe_var currentHashLocal
	[[ "$3" != "" ]] && _messagePlain_request 'dd if='"$3"' bs=2048 count=$(bc <<< '"'""$currentHash_bytes"' / 2048'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256'
	[[ "$currentHash" != "$currentHashLocal" ]] && _messageFAIL
	
	rm -f "$scriptLocal"/hash-download.txt
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
	[[ "$2" != "" ]] && currentHash="$2"
	[[ "$2" == "" ]] && currentHash=$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "_hash-ubdist.txt" | head -n 9 | tail -n 1)
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
		#_rclone_limited cat distLLC_release:/ubDistFetch/core.tar.xz | _get_extract_ubDistBuild-tar xv --overwrite
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


