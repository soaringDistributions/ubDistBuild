
# Intended to create an image solely for online installer steps , a small image ingredient to follow up with subsequent offline build from other more de-facto standard ingredients.

_create_ingredientVM() {
    _create_ingredientVM_image "$@"

    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-cp "$@"
    then
        exit 1
    fi
    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-rm "$@"
    then
        exit 1
    fi

    _create_ingredientVM_online "$@"
}

_create_ingredientVM_image() {
    _messageNormal '##### init: _create_ingredientVM_image'

	mkdir -p "$scriptLocal"
	
	

    _messagePlain_nominal '_createVMimage-micro'
    unset ubVirtImageOverride
    export ubVirtImageOverride="vm-ingredient.img"
	_createVMimage-micro "$@"

    

    _messagePlain_nominal '> _openImage'

	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)



    _messagePlain_nominal 'debootstrap'
    ! sudo -n debootstrap --variant=minbase --arch amd64 bookworm "$globalVirtFS" && _messageFAIL

    #_messagePlain_nominal 'fstab'
    #_createVMfstab

    _messagePlain_nominal 'os: globalVirtFS: write: fs'
    cat << CZXWXcRMTo8EmM8i4d | tee -a "$globalVirtFS"/etc/sudoers > /dev/null
#_____
#Defaults	env_reset
#Defaults	mail_badpass
#Defaults	secure_path="/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Defaults  env_keep += "currentChroot"
Defaults  env_keep += "chrootName"

root	ALL=(ALL:ALL) ALL
#user   ALL=(ALL:ALL) NOPASSWD: ALL
#pi ALL=(ALL:ALL) NOPASSWD: ALL

user ALL=(ALL:ALL) NOPASSWD: ALL

%admin   ALL=(ALL:ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
%wheel   ALL=(ALL:ALL) NOPASSWD: ALL
#%sudo	ALL=(ALL:ALL) ALL

# Important. Prevents possibility of appending to sudoers again by 'rotten_install.sh' .
noMoreRotten

CZXWXcRMTo8EmM8i4d



    _messagePlain_nominal '> _closeImage'
	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL

    
    _messagePlain_nominal '> _openChRoot'
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)



    _messagePlain_nominal '> getMost backend'
    export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	

    _messagePlain_nominal 'apt'
	_getMost_backend apt-get update
	_getMost_backend_aptGetInstall auto-apt-proxy
    _getMost_backend_aptGetInstall apt-transport-https
    _getMost_backend_aptGetInstall apt-fast


    _messagePlain_nominal 'dependencies'
    _getMost_backend_aptGetInstall ca-certificates
	
	_getMost_backend_aptGetInstall apt-utils

	_getMost_backend_aptGetInstall aria2 curl gpg
	_getMost_backend_aptGetInstall gnupg
	_getMost_backend_aptGetInstall lsb-release

	_getMost_backend_aptGetInstall btrfs-tools
	_getMost_backend_aptGetInstall btrfs-progs
	_getMost_backend_aptGetInstall btrfs-compsize
	_getMost_backend_aptGetInstall zstd
    
	_getMost_backend_aptGetInstall sudo
    

    _messagePlain_nominal 'hostnamectl'
	_getMost_backend_aptGetInstall hostnamectl
	#_getMost_backend_aptGetInstall systemd
	_chroot hostnamectl set-hostname default


	_messagePlain_nominal 'tzdata, locales'
	_getMost_backend_aptGetInstall tzdata
	_getMost_backend_aptGetInstall locales
	

	_messagePlain_nominal 'timedatectl, update-locale, localectl'
	[[ -e "$globalVirtFS"/usr/share/zoneinfo/America/New_York ]] && _chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
	_chroot timedatectl set-timezone US/Eastern
	_chroot update-locale LANG=en_US.UTF-8 LANGUAGE
	_chroot localectl set-locale LANG=en_US.UTF-8
	_chroot localectl --no-convert set-x11-keymap us pc104
	
    
	_messagePlain_nominal 'useradd, usermod'
    _chroot useradd -m user
    _chroot usermod -s /bin/bash root
    _chroot usermod -s /bin/bash user

    groupadd users
    groupadd disk

	_chroot usermod -a -G sudo user
	_chroot usermod -a -G sudo wheel

	_chroot usermod -a -G sudo users
	_chroot usermod -a -G disk users


    _messagePlain_nominal 'apt: upgrade'
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade



    _messagePlain_nominal '> _closeChroot'
	! "$scriptAbsoluteLocation" _closeChroot && _messagePlain_bad 'fail: _closeChroot' && _messageFAIL
}

_create_ingredientVM_online() {
    _messageNormal '##### init: _create_ingredientVM_online'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL



    _messagePlain_nominal 'report: disk usage'
    _chroot bash -c 'df --block-size=1000000 --output=used / | tr -dc '0-9' | tee /report-micro-diskUsage'

    
    _messagePlain_nominal '_get_veracrypt'
    _create_ingredientVM_ubiquitous_bash '_get_veracrypt'


    _messagePlain_nominal 'nix package manager'
    _create_ingredientVM_ubiquitous_bash '_test_nix-env'


    _messagePlain_nominal 'nix package manager - packages'
    _create_ingredientVM_ubiquitous_bash '_get_from_nix'


    #_messagePlain_nominal '_test_cloud'
    #_create_ingredientVM_ubiquitous_bash '_test_cloud'


    _messagePlain_nominal '_test_linode_cloud'
    _create_ingredientVM_ubiquitous_bash '_test_linode_cloud'

    
    _messagePlain_nominal '_test_croc'
    _create_ingredientVM_ubiquitous_bash '_test_croc'


    _messagePlain_nominal '_test_rclone'
    _create_ingredientVM_ubiquitous_bash '_test_rclone'


    _messagePlain_nominal '_test_terraform'
    _create_ingredientVM_ubiquitous_bash '_test_terraform'


    _messagePlain_nominal '_test_vagrant'
    _create_ingredientVM_ubiquitous_bash '_test_vagrant'


    #firejail


    #digimend


    _messagePlain_nominal 'apt-key: vbox'
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | _chroot apt-key add -
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | _chroot apt-key add -

    _messagePlain_nominal 'apt-key: docker'
    curl -fsSL https://download.docker.com/linux/debian/gpg | _chroot apt-key add -
	local aptKeyFingerprint
	aptKeyFingerprint=$(_chroot apt-key fingerprint 0EBFCD88 2> /dev/null)
	[[ "$aptKeyFingerprint" == "" ]] && _messagePlain_bad 'bad: fail: docker apt-key' && _messageFAIL

    _messagePlain_nominal 'apt-key: hashicorp (terraform, vagrant)'
    curl -fsSL https://apt.releases.hashicorp.com/gpg | _chroot apt-key add -



    _messagePlain_nominal '> _closeChroot'
	! "$scriptAbsoluteLocation" _closeChroot && _messagePlain_bad 'fail: _closeChroot' && _messageFAIL
}





_create_ingredientVM_zeroFill() {
    _messageNormal '##### init: _create_ingredientVM_online'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL



    _messagePlain_nominal 'zero fill'
    _chroot mount -o remount,compress=none /
	_chroot rm -f /fill > /dev/null 2>&1
	_chroot dd if=/dev/zero of=/fill bs=1M count=1 oflag=append conv=notrunc status=progress
	#_chroot btrfs property set /fill compression ""
	_chroot dd if=/dev/zero of=/fill bs=1M oflag=append conv=notrunc status=progress
	_chroot rm -f /fill
	
	if [[ "$skimfast" == "true" ]]
	then
		_chroot mount -o remount,compress=zstd:2 /
	else
		_chroot mount -o remount,compress=zstd:9 /
	fi



    _messagePlain_nominal '> _closeChroot'
	! "$scriptAbsoluteLocation" _closeChroot && _messagePlain_bad 'fail: _closeChroot' && _messageFAIL
}









_create_ingredientVM_diskUsage() {
    _chroot bash -c '(echo ; echo '"$1"') | tee -a /report-micro-diskUsage'
    _chroot bash -c 'df --block-size=1000000 --output=used / | tr -dc '0-9' | tee -a /report-micro-diskUsage'
}

_create_ingredientVM_ubiquitous_bash() {
    _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"$1"
    
    _create_ingredientVM_diskUsage "$1"
}

_create_ingredientVM_ubiquitous_bash-cp() {
    _messageNormal '##### init: _create_ingredientVM_ubiquitous_bash-cp'
	
	local functionEntryPWD="$PWD"

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="vm-ingredient.img"



    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

    
    
	# https://superuser.com/questions/1559417/how-to-discard-only-mode-changes-with-git
	cd "$scriptLib"/ubiquitous_bash
	_messagePlain_probe_cmd ls -ld _lib/kit/app/researchEngine
	local currentConfig
	currentConfig=$(git config core.fileMode)
	_messagePlain_probe_cmd git config core.fileMode true
	_messagePlain_probe_cmd find . -type f -exec chmod 644 {} \;
	_messagePlain_probe_cmd find . -type d -exec chmod 755 {} \;
	#git reset --hard
	_messagePlain_probe "git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/'"
	#git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/'
	#git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | git apply

	# ATTRIBUTION: ChatGPT o1-preview 2024-11-18
	git diff -p | awk '
	  /^diff --git/ { diff = $0; next }
	  /^old mode/   { old_mode = $0; next }
	  /^new mode/   { new_mode = $0;
	                  print diff;
	                  print old_mode;
	                  print new_mode;
	                }' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | tee /dev/sdtout | git apply

	sleep 9
	git config core.fileMode "$currentConfig"
	cd "$functionEntryPWD"

	_messagePlain_probe_cmd ls -l "$scriptLib"/ubiquitous_bash/ubiquitous_bash.sh

	sudo -n mkdir -p "$globalVirtFS"/home/user/temp_micro/test_"$ubiquitiousBashIDnano"
	sudo -n cp -a "$scriptLib"/ubiquitous_bash "$globalVirtFS"/home/user/temp_micro/test_"$ubiquitousBashIDnano"/
	
	_chroot chown -R user:user /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/
	#_chroot sudo -n -u user bash -c 'cd /home/user/temp_micro/test_"'"$ubiquitousBashIDnano"'"/ ; git reset --hard'

	_messagePlain_probe_cmd _chroot ls -l /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh

	if ! _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh _true'
	then
		_messageFAIL
	fi

    if _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh _false'
	then
		_messageFAIL
	fi


    _messagePlain_nominal '> _closeChroot'
	! "$scriptAbsoluteLocation" _closeChroot && _messagePlain_bad 'fail: _closeChroot' && _messageFAIL
}
_create_ingredientVM_ubiquitous_bash-rm() {
    _messageNormal '##### init: _create_ingredientVM_ubiquitous_bash-rm'
	
	local functionEntryPWD="$PWD"

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="vm-ingredient.img"
    


    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL



	## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	_chroot rm -rf /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/
	_chroot rmdir /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/
	_chroot rmdir /home/user/temp_micro/



    _messagePlain_nominal '> _closeChroot'
	! "$scriptAbsoluteLocation" _closeChroot && _messagePlain_bad 'fail: _closeChroot' && _messageFAIL
}
