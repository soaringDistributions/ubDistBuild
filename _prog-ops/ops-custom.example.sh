_custom() {
	true
}

_custom-expand() {
	true
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

