##### Core




_getCore_ubDistFetch() {
	_rclone_limited --progress copy distLLC_release:/ubDistFetch/core.tar.xz ./_lib/
}

_get_ubDistHome() {
	_rclone_limited --progress copy distLLC_release:/ubDistHome/ubDistHome.tar.xz ./_lib/
}





_create_ubDistBuild() {
	
	#create vm.img
	
	
	
	# https://gist.github.com/superboum/1c7adcd967d3e15dfbd30d04b9ae6144
	#debootstrap --variant=minbase --components=main --include=inetutils-ping,iproute ...
	
	
	
	true
}




_custom_ubDistBuild() {
	# TODO: Users, sudoers, etc, customization.
	
	# TODO: display manager autologin
	
	# TODO: copy in all software
	
	# TODO: _setup for all infrastructure/installations
	
	true
}







_ubDistBuild() {
	
	# TODO: partition, debootstrap, efi (sufficient to manually craft HOME/KDE package)
	
	
	
	_getCore_ubDistFetch
	
	_get_ubDistHome
	
	
	
	_create_ubDistBuild
	
	
	_custom_ubDistBuild
	
}





_refresh_anchors() {
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_getCore_ubDistFetch
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_get_ubDistHome
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_custom_ubDistBuild
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_ubDistBuild
}

