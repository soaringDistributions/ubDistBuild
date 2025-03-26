
# Intended to create an image solely for online installer steps , a small image ingredient to follow up with subsequent offline build from other more de-facto standard ingredients.

# WARNING: May be untested.
_package_ingredientVM() {
    _messageNormal '##### init: _package_ingredientVM'


	rm -f "$scriptLocal"/vm-ingredient.img.flx > /dev/null 2>&1

    # Maybe ~15MB/2GB smaller.
    #! cat "$scriptLocal"/vm-ingredient.img | tee >(openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$scriptLocal"/vm-ingredient.img.hash.txt) | xz -9e -T1 -z - > "$scriptLocal"/vm-ingredient.img.flx && _messagePlain_bad 'bad: FAIL: xz' && _messageFAIL

    ! cat "$scriptLocal"/vm-ingredient.img | tee >(openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$scriptLocal"/vm-ingredient.img.hash.txt) | xz -9e -T6 -z - > "$scriptLocal"/vm-ingredient.img.flx && _messagePlain_bad 'bad: FAIL: xz' && _messageFAIL

	#--fast=65537
	#cat "$scriptLocal"/vm-ingredient.img | lz4 -z --fast=1 - "$scriptLocal"/vm-ingredient.img.flx

    echo
    cat "$scriptLocal"/vm-ingredient.img.hash.txt
	
	! [[ -e "$scriptLocal"/vm-ingredient.img.flx ]] && _messagePlain_bad 'bad: FAIL: missing: vm-ingredient.img.flx' && _messageFAIL
	
	return 0
}
_split_ingredientVM() {
    _messageNormal '##### init: _split_ingredientVM'
	local functionEntryPWD
	functionEntryPWD="$PWD"

	cd "$scriptLocal"

    ! _ubDistBuild_split_procedure ./vm-ingredient.img.flx && _messagePlain_bad 'bad: FAIL: split' && _messageFAIL

    rm -f ./vm-ingredient.img.flx > /dev/null 2>&1

    cd "$functionEntryPWD"
    return 0
}
_get_ingredientVM() {
    _messageNormal '##### init: _get_ingredientVM'
    rm -f "$scriptLocal"/vm-ingredient.img > /dev/null 2>&1
    rm -f "$scriptLocal"/vm-ingredient.img.hash-download.txt > /dev/null 2>&1
    rm -f "$scriptLocal"/vm-ingredient.img.hash-upstream.txt > /dev/null 2>&1
    
    local releaseLabel="$1"
    #[[ "$releaseLabel" == "" ]] && releaseLabel=latest
    [[ "$releaseLabel" == "" ]] && releaseLabel=internal
    #-whirlpool
    if ! _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-ingredient.img.flx" | xz -d | tee >(openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$scriptLocal"/vm-ingredient.img.hash-download.txt) > "$scriptLocal"/vm-ingredient.img
    then
        _messagePlain_bad 'bad: FAIL: get'
        _messageFAIL
    fi

    # Hash
    echo
    cat "$scriptLocal"/vm-ingredient.img.hash-download.txt

    _wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-ingredient.img.hash.txt" > "$scriptLocal"/vm-ingredient.img.hash-upstream.txt
    #$(_wget_githubRelease-stdout "soaringDistributions/ubDistBuild" "$releaseLabel" "vm-ingredient.img.hash.txt" | tr -dc 'a-f0-9')
    if [[ $(cat "$scriptLocal"/vm-ingredient.img.hash-upstream.txt | tr -dc 'a-f0-9') == $(cat "$scriptLocal"/vm-ingredient.img.hash-download.txt | tr -dc 'a-f0-9') ]]
    then
        _messagePlain_good 'good: hash'
        return 0
    fi
    
    _messagePlain_bad 'bad: FAIL: hash'
    _messageFAIL
}
_get_fromTag_ingredientVM() {
    _messageNormal '##### init: _get_fromTag_ingredientVM'
    rm -f "$scriptLocal"/vm-ingredient.img > /dev/null 2>&1
    rm -f "$scriptLocal"/vm-ingredient.img.hash-download.txt > /dev/null 2>&1
    rm -f "$scriptLocal"/vm-ingredient.img.hash-upstream.txt > /dev/null 2>&1
    
    local currentTag="$1"
    #[[ "$currentTag" == "" ]] && currentTag=latest
    #[[ "$currentTag" == "" ]] && currentTag=internal
    #-whirlpool
    if ! _wget_githubRelease-fromTag_join-stdout "soaringDistributions/ubDistBuild" "$currentTag" "vm-ingredient.img.flx" | xz -d | tee >(openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$scriptLocal"/vm-ingredient.img.hash-download.txt) > "$scriptLocal"/vm-ingredient.img
    then
        _messagePlain_bad 'bad: FAIL: get'
        _messageFAIL
    fi

    # Hash
    echo
    cat "$scriptLocal"/vm-ingredient.img.hash-download.txt

    _wget_githubRelease-fromTag-stdout "soaringDistributions/ubDistBuild" "$currentTag" "vm-ingredient.img.hash.txt" > "$scriptLocal"/vm-ingredient.img.hash-upstream.txt
    #$(_wget_githubRelease-fromTag-stdout "soaringDistributions/ubDistBuild" "$currentTag" "vm-ingredient.img.hash.txt" | tr -dc 'a-f0-9')
    if [[ $(cat "$scriptLocal"/vm-ingredient.img.hash-upstream.txt | tr -dc 'a-f0-9') == $(cat "$scriptLocal"/vm-ingredient.img.hash-download.txt | tr -dc 'a-f0-9') ]]
    then
        _messagePlain_good 'good: hash'
        return 0
    fi
    
    _messagePlain_bad 'bad: FAIL: hash'
    _messageFAIL
}
_join_ingredientVM() {
    _messageNormal '##### init: _join_ingredientVM'

    ! [[ -e "$scriptLocal"/"vm-ingredient.img.flx.part00" ]] && _messagePlain_bad 'bad: FAIL: missing: vm-ingredient.img.flx.part00' && _messageFAIL

    rm -f "$scriptLocal"/vm-ingredient.img.hash-join.txt > /dev/null 2>&1

    rm -f "$scriptLocal"/vm-ingredient.img > /dev/null 2>&1
    ( local currentIteration=""
    for currentIteration in $(seq -w 0 50 | sort -r)
    do
        #_messagePlain_probe_var currentIteration
        [[ -e "$scriptLocal"/vm-ingredient.img.flx.part"$currentIteration" ]] && dd if="$scriptLocal"/vm-ingredient.img.flx.part"$currentIteration" bs=1M status=progress
    done ) | xz -d > "$scriptLocal"/vm-ingredient.img

    cat "$scriptLocal"/vm-ingredient.img | openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$scriptLocal"/vm-ingredient.img.hash-join.txt

    echo
    cat "$scriptLocal"/vm-ingredient.img.hash-join.txt

    # If hash-upstream.txt or hash.txt are available, assume these may have been downloaded along with the now joined vm-ingredient.img file, compare, and if match, report good.
    if [[ $(cat "$scriptLocal"/vm-ingredient.img.hash-upstream.txt 2> /dev/null | tr -dc 'a-f0-9') == $(cat "$scriptLocal"/vm-ingredient.img.hash-join.txt | tr -dc 'a-f0-9') ]]
    then
        _messagePlain_good 'good: hash'
        return 0
    fi

    return 0
}


_create_ingredientVM() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1

    _create_ingredientVM_image "$@"

    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-cp "$@"
    then
        _stop 1
    fi

    _create_ingredientVM_online "$@"
    
    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-rm "$@"
    then
        _stop 1
    fi

    _create_ingredientVM_zeroFill "$@"
}

_create_ingredientVM_image() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_image'

	mkdir -p "$scriptLocal"
	

    [[ -e "$scriptLocal"/"vm-ingredient.img" ]] && _messagePlain_bad 'bad: fail: exists: vm-ingredient.img' && _messageFAIL
	

    _messagePlain_nominal '_createVMimage-micro'
    unset ubVirtImageOverride
	_createVMimage-micro "$@"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"

    

    _messagePlain_nominal '> _openImage'

	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)



    _messagePlain_nominal 'remount: compression'
    sudo -n mount -o remount,compress=zstd:15 "$globalVirtFS"


    _messagePlain_nominal 'debootstrap'
    ! sudo -n debootstrap --variant=minbase --arch amd64 bookworm "$globalVirtFS" && _messageFAIL

    #_messagePlain_nominal 'fstab'
    #_createVMfstab

    _messagePlain_nominal 'os: globalVirtFS: write: fs'
    # ATTENTION: Unusual. A complete sudoers file is written here largely for formality, in case 'sudo' has somehow already been installed and may somehow be needed. Later, before sudo is deliberately installed, the sudoers file is deleted, then after sudo is deliberately installed, only the necessary additions are appended.
    #sudo -n rm -f "$globalVirtFS"/etc/sudoers
    #tee -a
    cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/sudoers > /dev/null
#
# This file MUST be edited with the 'visudo' command as root.
#
# Please consider adding local content in /etc/sudoers.d/ instead of
# directly modifying this file.
#
# See the man page for details on how to write a sudoers file.
#
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# This fixes CVE-2005-4890 and possibly breaks some versions of kdesu
# (#1011624, https://bugs.kde.org/show_bug.cgi?id=452532)
Defaults        use_pty

# This preserves proxy settings from user environments of root
# equivalent users (group sudo)
#Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"

# This allows running arbitrary commands, but so does ALL, and it means
# different sudoers have their choice of editor respected.
#Defaults:%sudo env_keep += "EDITOR"

# Completely harmless preservation of a user preference.
#Defaults:%sudo env_keep += "GREP_COLOR"

# While you shouldn't normally run git as root, you need to with etckeeper
#Defaults:%sudo env_keep += "GIT_AUTHOR_* GIT_COMMITTER_*"

# Per-user preferences; root won't have sensible values for them.
#Defaults:%sudo env_keep += "EMAIL DEBEMAIL DEBFULLNAME"

# "sudo scp" or "sudo rsync" should be able to use your SSH agent.
#Defaults:%sudo env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"

# Ditto for GPG agent
#Defaults:%sudo env_keep += "GPG_AGENT_INFO"

# Host alias specification

# User alias specification

# Cmnd alias specification

# User privilege specification
root    ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL

# See sudoers(5) for more information on "@include" directives:

@includedir /etc/sudoers.d
#_____
#Defaults       env_reset
#Defaults       mail_badpass
#Defaults       secure_path="/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Defaults  env_keep += "currentChroot"
Defaults  env_keep += "chrootName"

root    ALL=(ALL:ALL) ALL
#user   ALL=(ALL:ALL) NOPASSWD: ALL
#pi ALL=(ALL:ALL) NOPASSWD: ALL

user ALL=(ALL:ALL) NOPASSWD: ALL

%admin   ALL=(ALL:ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
%wheel   ALL=(ALL:ALL) NOPASSWD: ALL
#%sudo  ALL=(ALL:ALL) ALL

# Important. Prevents possibility of appending to sudoers again by 'rotten_install.sh' .
# End users may delete this long after dist/OS install is done.
#noMoreRotten

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


    _messagePlain_nominal 'apt: minimal'
    _getMost_backend_aptGetInstall ca-certificates
	
	_getMost_backend_aptGetInstall apt-utils

    _getMost_backend_aptGetInstall wget
	_getMost_backend_aptGetInstall aria2 curl gpg
	_getMost_backend_aptGetInstall gnupg
	_getMost_backend_aptGetInstall lsb-release
	
	_getMost_backend_aptGetInstall xz-utils

    _getMost_backend_aptGetInstall openssl jq git lz4 bc xxd
    _getMost_backend_aptGetInstall pv
    _getMost_backend_aptGetInstall gh

    _getMost_backend_aptGetInstall p7zip
	_getMost_backend_aptGetInstall p7zip-full
    _getMost_backend_aptGetInstall unzip zip
    _getMost_backend_aptGetInstall lbzip2

	_getMost_backend_aptGetInstall btrfs-tools
	_getMost_backend_aptGetInstall btrfs-progs
	_getMost_backend_aptGetInstall btrfs-compsize
	_getMost_backend_aptGetInstall zstd
    
    # ATTENTION: Debian Bookworm sudoers default correctly changes the PATH for root user. Without this, 'cmd.sh', 'bootOnce', etc, will all FAIL - such commands as 'sudo -n poweroff' will FAIL .
    sudo -n rm -f "$globalVirtFS"/etc/sudoers
	_getMost_backend_aptGetInstall sudo
    cat << CZXWXcRMTo8EmM8i4d | sudo -n tee -a "$globalVirtFS"/etc/sudoers > /dev/null
#_____
#Defaults       env_reset
#Defaults       mail_badpass
#Defaults       secure_path="/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Defaults  env_keep += "currentChroot"
Defaults  env_keep += "chrootName"

root    ALL=(ALL:ALL) ALL
#user   ALL=(ALL:ALL) NOPASSWD: ALL
#pi ALL=(ALL:ALL) NOPASSWD: ALL

user ALL=(ALL:ALL) NOPASSWD: ALL

%admin   ALL=(ALL:ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
%wheel   ALL=(ALL:ALL) NOPASSWD: ALL
#%sudo  ALL=(ALL:ALL) ALL

# Important. Prevents possibility of appending to sudoers again by 'rotten_install.sh' .
# End users may delete this long after dist/OS install is done.
#noMoreRotten

CZXWXcRMTo8EmM8i4d

    _messagePlain_nominal 'hostnamectl'
	_getMost_backend_aptGetInstall hostnamectl
	#_getMost_backend_aptGetInstall systemd
	_chroot hostnamectl set-hostname default


	_messagePlain_nominal 'tzdata, locales'
	_getMost_backend_aptGetInstall tzdata
	_getMost_backend_aptGetInstall locales

    
	#_chroot tasksel install standard
    _getMost_backend_aptGetInstall systemd


    _messagePlain_nominal 'apt: DEPENDENCIES'
    ! _getMost_backend_aptGetInstall fuse expect software-properties-common libvirt-daemon-system libvirt-daemon libvirt-daemon-driver-qemu libvirt-clients man-db && _messagePlain_bad 'bad: FAIL: apt-get install DEPENDENCIES' && _messageFAIL
	


	_messagePlain_nominal 'timedatectl, update-locale, localectl'
	[[ -e "$globalVirtFS"/usr/share/zoneinfo/America/New_York ]] && _chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
	#_chroot timedatectl set-timezone US/Eastern
	#_chroot update-locale LANG=en_US.UTF-8 LANGUAGE
	#_chroot localectl set-locale LANG=en_US.UTF-8
	#_chroot localectl --no-convert set-x11-keymap us pc104
	
    
	_messagePlain_nominal 'useradd, usermod'
    _chroot useradd -m user
    _chroot usermod -s /bin/bash root
    _chroot usermod -s /bin/bash user

    _rand_passwd() { cat /dev/urandom 2> /dev/null | base64 2> /dev/null | tr -dc 'a-zA-Z0-9' 2> /dev/null | head -c "$1" 2> /dev/null ; }

    echo 'root:'$(_rand_passwd 15) | _chroot chpasswd
    echo 'root:'$(_rand_passwd 32) | _chroot chpasswd
    
    echo 'user:'$(_rand_passwd 15) | _chroot chpasswd
    echo 'user:'$(_rand_passwd 32) | _chroot chpasswd

    _chroot groupadd users
    _chroot groupadd disk

	_chroot usermod -a -G sudo user
	_chroot usermod -a -G wheel user
	_chroot usermod -a -G disk user
	_chroot usermod -a -G users user


    _messagePlain_nominal 'apt: upgrade'
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade


    _messagePlain_nominal 'apt: clean'
    _chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y clean
    _chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y autoclean


    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    return 0
}

_create_ingredientVM_online() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_online'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL


    # WARNING: skimfast - No production use!
    # WARNING: Do NOT pass skimfast to this function during normal builds. ONLY export the skimfast variable in CI YAML scripts specifically for very rapid development/testing and NOT production use!
    _messagePlain_nominal 'remount: compression'
	if [[ "$skimfast" == "true" ]]
	then
		#_chroot mount -o remount,compress=zstd:2 /
        _chroot mount -o remount,compress=zstd:13 /
	else
		#_chroot mount -o remount,compress=zstd:9 /
        _chroot mount -o remount,compress=zstd:15 /
	fi


    _messagePlain_nominal 'report: disk usage'
    _chroot bash -c 'df --block-size=1000000 --output=used / | tr -dc "0-9" | tee /report-micro-diskUsage'

    
    # Enable if 'whirlpool' hash, etc, may be used.
    #_messagePlain_nominal '_custom_splice_opensslConfig'
    #_create_ingredientVM_ubiquitous_bash '_custom_splice_opensslConfig'



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


    
    _messagePlain_nominal '_get_veracrypt'
    _create_ingredientVM_ubiquitous_bash '_get_veracrypt' 2> >(tail -n 30 >&2)

    
    _messagePlain_nominal 'ollama install'
    curl -fsSL https://ollama.com/install.sh | _chroot sudo -n -u user sh 2> >(tail -n 30 >&2)
    _chroot bash -c '(echo ; echo 'ollama install') | tee -a /report-micro-diskUsage'
    _chroot bash -c 'df --block-size=1000000 --output=used / | tr -dc "0-9" | tee -a /report-micro-diskUsage'


    _messagePlain_nominal 'nix package manager'
    _create_ingredientVM_ubiquitous_bash '_test_nix-env'


    _messagePlain_nominal 'nix package manager - packages'
    _create_ingredientVM_ubiquitous_bash '_get_from_nix'


    _messagePlain_nominal 'nix package manager - gc'
    _chroot sudo -n -u user /bin/bash -l -c 'cd ; nix-store --gc'


    #_messagePlain_nominal '_test_cloud'
    #_create_ingredientVM_ubiquitous_bash '_test_cloud'


    _messagePlain_nominal '_test_linode_cloud'
    _create_ingredientVM_ubiquitous_bash '_test_linode_cloud'

    
    _messagePlain_nominal '_test_croc'
    _create_ingredientVM_ubiquitous_bash '_test_croc'


    _messagePlain_nominal '_test_rclone'
    _create_ingredientVM_ubiquitous_bash '_test_rclone'


    # May be achieved in practice with Debian packages from third-party repository.
    #_messagePlain_nominal '_test_terraform'
    ##sudo -n apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    ##vagrant-libvirt vagrant
    #_create_ingredientVM_ubiquitous_bash '_test_terraform'


    # May be achieved in practice with Debian packages from third-party repository.
    #_messagePlain_nominal '_test_vagrant_build'
    ##sudo -n apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    ##vagrant-libvirt vagrant
    #create_ingredientVM_ubiquitous_bash '_test_vagrant_build'


    #firejail


    #digimend



    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    return 0
}

_create_ingredientVM_report() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_report'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL


    _chroot find /bin/ /usr/bin/ /sbin/ /usr/sbin/ | sudo -n tee "$globalVirtFS"/micro-binReport.txt > /dev/null
    _chroot find /home/user/.nix-profile/bin | sudo -n tee -a "$globalVirtFS"/micro-binReport.txt > /dev/null 2>&1
    _chroot find /home/user/.gcloud/google-cloud-sdk/bin | sudo -n tee -a "$globalVirtFS"/micro-binReport.txt > /dev/null
    _chroot find /home/user/.ebcli-virtual-env/executables | sudo -n tee -a "$globalVirtFS"/micro-binReport.txt > /dev/null 2>&1
    sudo -n cp -f "$globalVirtFS"/micro-binReport.txt "$scriptLocal"/micro-binReport.txt
    sudo -n chown "$USER":"$USER" "$scriptLocal"/micro-binReport.txt

    _chroot dpkg --get-selections | cut -f1 | sudo -n tee "$globalVirtFS"/micro-dpkg.txt > /dev/null
    sudo -n cp -f "$globalVirtFS"/micro-dpkg.txt "$scriptLocal"/micro-dpkg.txt
    sudo -n chown "$USER":"$USER" "$scriptLocal"/micro-dpkg.txt


    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    return 0
}




_create_ingredientVM_zeroFill() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_zeroFill'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL



    _messagePlain_nominal 'zero fill: root'
    _chroot mount -o remount,compress=none /
	_chroot rm -f /fill > /dev/null 2>&1
	_chroot dd if=/dev/zero of=/fill bs=1M count=1 oflag=append conv=notrunc status=progress
	#_chroot btrfs property set /fill compression ""
	_chroot dd if=/dev/zero of=/fill bs=1M oflag=append conv=notrunc status=progress
	_chroot rm -f /fill
	
    # WARNING: skimfast - No production use!
    # WARNING: Do NOT pass skimfast to this function during normal builds. ONLY export the skimfast variable in CI YAML scripts specifically for very rapid development/testing and NOT production use!
	if [[ "$skimfast" == "true" ]]
	then
		#_chroot mount -o remount,compress=zstd:2 /
        _chroot mount -o remount,compress=zstd:13 /
	else
		#_chroot mount -o remount,compress=zstd:9 /
        _chroot mount -o remount,compress=zstd:15 /
	fi


    _messagePlain_nominal 'zero fill: boot'
	_chroot rm -f /boot/fill > /dev/null 2>&1
	_chroot dd if=/dev/zero of=/boot/fill bs=1M count=1 oflag=append conv=notrunc status=progress
	_chroot dd if=/dev/zero of=/boot/fill bs=1M oflag=append conv=notrunc status=progress
	_chroot rm -f /boot/fill



    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    return 0
}









_create_ingredientVM_diskUsage() {
    _chroot bash -c '(echo ; echo '"$1"') | tee -a /report-micro-diskUsage'
    _chroot bash -c 'df --block-size=1000000 --output=used / | tr -dc "0-9" | tee -a /report-micro-diskUsage'
}

_create_ingredientVM_ubiquitous_bash() {
    _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"$1"
    
    _create_ingredientVM_diskUsage "$1"
}

_create_ingredientVM_ubiquitous_bash_sequence-cp() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_ubiquitous_bash-cp'
    _start
	
	local functionEntryPWD="$PWD"

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"



    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

    

	_messagePlain_nominal 'remount: compression'
    sudo -n mount -o remount,compress=zstd:15 "$globalVirtFS"


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
	                }' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | tee /dev/stdout > "$safeTmp"/patch.txt
    cat "$safeTmp"/patch.txt | git apply

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
    

    #_messagePlain_nominal '_setupUbiquitous , _custom_splice_opensslConfig'
    #_chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"_setupUbiquitous"
    #_chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"_custom_splice_opensslConfig"


    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    _stop
    #return 0
}
_create_ingredientVM_ubiquitous_bash-cp() {
    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash_sequence-cp "$@"
    then
        _stop 1
    fi
    return 0
}
_create_ingredientVM_ubiquitous_bash-rm() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    _messageNormal '##### init: _create_ingredientVM_ubiquitous_bash-rm'
	
	local functionEntryPWD="$PWD"

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    


    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL



	_messagePlain_nominal 'remount: compression'
    sudo -n mount -o remount,compress=zstd:15 "$globalVirtFS"


    ## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	_chroot rm -rf /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/
	_chroot rmdir /home/user/temp_micro/test_"$ubiquitiousBashIDnano"/
	_chroot rmdir /home/user/temp_micro/



    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    return 0
}






_openChRoot_ingredient() {
    # WARNING: Variable "$scriptLocal" will be defined differently, if at all, in an interactive shell outside the context of this script.
    #  Thus, this function exists mostly to provide access to the "_openChRoot" command with the  'ubVirtImageOverride' variable coorrectly set, with the bonus of not changing with the user's 'ubVirtImageOverride' variable.
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    "$scriptAbsoluteLocation" _openChRoot "$@"
}
#--force
_closeChRoot_ingredient() {
    # WARNING: Variable "$scriptLocal" will be defined differently, if at all, in an interactive shell outside the context of this script.
    #  Thus, this function exists mostly to provide access to the "_openChRoot" command with the  'ubVirtImageOverride' variable coorrectly set, with the bonus of not changing with the user's 'ubVirtImageOverride' variable.
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    "$scriptAbsoluteLocation" _closeChRoot "$@"
}

_create_ingredientVM_experiment() {
    type _if_cygwin > /dev/null 2>&1 && _if_cygwin && _messagePlain_warn 'warn: _if_cygwin' && _stop 1
    if [[ ! -e "$scriptLocal"/vm-ingredient.img ]]
    then
        if !_create_ingredientVM_image "$@"
        then
            _messageFAIL
        fi
    fi
    
    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-cp "$@"
    then
        _stop 1
    fi
    
    _messageNormal '##### init: _experiment'

    mkdir -p "$scriptLocal"
    export ubVirtImageOverride="$scriptLocal"/"vm-ingredient.img"
    

    _messagePlain_nominal '> _openChRoot'
    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
    
    _messagePlain_nominal '_setupUbiquitous , _custom_splice_opensslConfig'
    sudo -n mount -o remount,compress=zstd:13 "$globalVirtFS"
    _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"_setupUbiquitous"
    _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh '"_custom_splice_opensslConfig"

    _chroot sudo -n -u user bash -c 'cd /home/user/temp_micro/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; bash -i'


    _messagePlain_nominal '> _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL


    if ! "$scriptAbsoluteLocation" _create_ingredientVM_ubiquitous_bash-rm "$@"
    then
        _stop 1
    fi

    return 0
}










