_custom() {
	true
}

_custom-expand() {
	local currentExitStatus
	currentExitStatus="0"
	
	_messageNormal '_custom-expand: dd'

	# ATTENTION: Expand ONLY the additional amount needed for custom additions . This is APPENDED .
	! dd if=/dev/zero bs=1M count=12000 >> "$scriptLocal"/vm.img && _messageFAIL
	
	
	_messageNormal '_custom-expand: growpart'
	! _openLoop && _messagePlain_bad 'fail: openLoop' && _messageFAIL
	
	export ubVirtPlatform="x64-efi"
	#_determine_rawFileRootPartition
	
	export ubVirtImagePartition="p5"
	
	local current_imagedev=$(cat "$scriptLocal"/imagedev)
	local current_rootpart=$(echo "$ubVirtImagePartition" | tr -dc '0-9')
	
	! _messagePlain_probe_cmd sudo -n growpart "$current_imagedev" "$current_rootpart" && _messageFAIL
	
	unset ubVirtPlatform
	unset ubVirtImagePartition
	
	! _closeLoop && _messagePlain_bad 'fail: closeLoop' && _messageFAIL
	
	_messageNormal '_custom-expand: btrfs resize'
	! _openChRoot && _messagePlain_bad 'fail: openChRoot' && _messageFAIL
	
	
	! _messagePlain_probe_cmd _chroot btrfs filesystem resize max / && _messageFAIL
	
	
	! _closeChRoot && _messagePlain_bad 'fail: closeChRoot' && _messageFAIL
	
	return 0
}

_custom-repo() {
	_git-custom-repo variant org repo
	
	_git-custom-repo variant org repo_bundle
}


_git-custom-repo() {
	! _openChRoot && _messageFAIL
	
	export INPUT_GITHUB_TOKEN="$GH_TOKEN"
	
	_chroot sudo -n --preserve-env=GH_TOKEN --preserve-env=INPUT_GITHUB_TOKEN -u user bash -c 'mkdir -p /home/user/core/'"$1"' ; cd /home/user/core/'"$1"' ; /home/user/ubDistBuild/ubiquitous_bash.sh _gitBest clone --recursive --depth 1 git@github.com:'"$2"'/'"$3"'.git'
	if ! sudo -n ls "$globalVirtFS"/home/user/core/"$1"/"$3"
	then
		_messagePlain_bad 'bad: FAIL: missing: '/home/user/core/"$1"/"$3"
		_messageFAIL
		_stop 1
		return 1
	fi
	
	! _closeChRoot && _messageFAIL
}

