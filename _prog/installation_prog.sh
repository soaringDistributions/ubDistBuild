
_test_prog() {
	_getDep pv

	_wantGetDep lsblk

	_wantGetDep unsquashfs
}

_gitMad_neighbors_procedure() {
	local functionEntryPWD
	functionEntryPWD="$PWD"

	[[ ! -e '/cygdrive/c/core/variant/ubdist_dummy' ]] && _messageFAIL
	cd '/cygdrive/c/core/variant/ubdist_dummy'
	_gitMad
	
	[[ ! -e '/cygdrive/c/core/variant/ubdist_puddleJumper' ]] && _messageFAIL
	cd '/cygdrive/c/core/variant/ubdist_puddleJumper'
	_gitMad
	
	cd "$functionEntryPWD"
}
_gitMad_neighbors() {
	"$scriptAbsoluteLocation" _gitMad_neighbors_procedure "$@"
}


_setup_install() {
	true

	#local currentBackupDir=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"
	
	#if [[ "$1" != "" ]] && [[ ! -e "$currentBackupDir" ]]
	#then
		#_messagePlain_bad 'fail: bad: invalid: missing: parameter: "$1": '"$currentBackupDir"
		#_messageFAIL
		#_stop 1
		#return 1
	#fi
	
	_install_wsl2
    #_install_vm-wsl2 "$@"

	local currentLOCALAPPDATA
	currentLOCALAPPDATA=$(cygpath "$LOCALAPPDATA")
	currentLOCALAPPDATA="$currentLOCALAPPDATA"/ubDistBuild
	mkdir -p "$currentLOCALAPPDATA"

	mkdir -p "$currentLOCALAPPDATA"/root
	_messagePlain_probe_cmd unzip -o "$scriptLib"/support/MSW/root_extra.zip -d /cygdrive/c
	_messagePlain_probe_cmd unzip -o "$scriptLib"/support/MSW/root_extra.zip -d "$currentLOCALAPPDATA"/root
	
	
	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL-FileManager" /v "" /d "Open with ubdistWSL-FileManager" /f
	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL-FileManager\command" /v "" /d '"C:\Program Files\WSL\wslg.exe" '"-d ubdist /home/user/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap dolphin \"%V\"" /f

	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL-FileManager" /v "" /d "Open with ubdistWSL-FileManager" /f
	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL-FileManager\command" /v "" /d '"C:\Program Files\WSL\wslg.exe" '"-d ubdist /home/user/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap dolphin \"%V\"" /f


	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL" /v "" /d "Open with ubdistWSL" /f
	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL\command" /v "" /d '"C:\Program Files\WSL\wsl.exe" '"-d ubdist" /f

	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL" /v "" /d "Open with ubdistWSL" /f
	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL\command" /v "" /d '"C:\Program Files\WSL\wsl.exe" '"-d ubdist" /f

	
	local currentMSWPath_associate
	currentMSWPath_associate=$(cygpath -w "$scriptLib"/support/MSW/associate.bat)


	# May be unusual. Unlike other apps, usability of native MSW equivalent for gEDA apps may not be expected.
	cmd /c "$currentMSWPath_associate" geda.schematic .sch gschem
	cmd /c "$currentMSWPath_associate" geda.pcb .pcb /usr/bin/pcb
	cmd /c "$currentMSWPath_associate" geda.fp .fp /usr/bin/pcb




	

	_messagePlain_probe_cmd _self_gitMad

	_messagePlain_probe_cmd _gitMad_neighbors

	sleep 5
}

_setup_uninstall() {
	true

	#_uninstall_vm-wsl2
}


















# Attempts to reduce adding the necessary Debian packages, from ~5minutes , to much less . However, in practice, '_getMinimal_cloud' , is already very minimal.
# Relies on several assumptions:
#  _setupUbiquitous   has definitely always already been called
#  apt-fast   either is or is not available, hardcoded




_getMinimal_cloud_ubDistBuild_noBoot_backend() {
    _messagePlain_probe "$@"
    sudo -n env XZ_OPT="-T0" DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -q --install-recommends -y "$@"
}

_getMinimal_cloud_ubDistBuild_noBoot() {
    echo 'APT::AutoRemove::RecommendsImportant "true";
APT::AutoRemove::SuggestsImportant "true";' | sudo -n tee /etc/apt/apt.conf.d/99autoremove-recommends > /dev/null

    #dpkg --add-architecture i386
    #apt-get update
    #libc6:i386 lib32z1
    
    _getMinimal_cloud_ubDistBuild_noBoot_backend --reinstall wget

    ##xz btrfs-tools grub-mkstandalone mkfs.vfat mkswap mmd mcopy mksquashfs
    #gpg pigz curl gdisk lz4 mawk jq gawk build-essential autoconf pkg-config bsdutils findutils patch tar gzip bzip2 sed lua-lpeg axel aria2 gh rsync pv expect libfuse2 udftools debootstrap cifs-utils dos2unix xxd debhelper p7zip nsis jp2a btrfs-progs btrfs-compsize zstd zlib1g coreutils util-linux kpartx openssl growisofs udev gdisk parted bc e2fsprogs xz-utils libreadline8 mkisofs genisoimage byobu xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools fdisk cloud-guest-utils
    ##dnsutils bind9-dnsutils bison libelf-dev elfutils flex libncurses-dev libudev-dev dwarves pahole cmake sockstat liblinear4 liblua5.3-0 nmap nmap-common socat dwarves pahole libssl-dev cpio libgtk2.0-0 libwxgtk3.0-gtk3-0v5 wipe iputils-ping nilfs-tools python3 sg3-utils cryptsetup php
    ##qemu-system-x86
    ##qemu-user qemu-utils
    _getMinimal_cloud_ubDistBuild_noBoot_backend gpg pigz curl gdisk lz4 mawk jq gawk build-essential autoconf pkg-config bsdutils findutils patch tar gzip bzip2 sed lua-lpeg axel aria2 gh rsync pv expect libfuse2 udftools debootstrap cifs-utils dos2unix xxd debhelper p7zip nsis jp2a btrfs-progs btrfs-compsize zstd zlib1g coreutils util-linux kpartx openssl growisofs udev gdisk parted bc e2fsprogs xz-utils libreadline8 mkisofs genisoimage byobu xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools fdisk cloud-guest-utils

    _messagePlain_probe apt-get remove --autoremove -y plasma-discover
    sudo -n env XZ_OPT="-T0" DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove --autoremove -y plasma-discover

    _messagePlain_probe _custom_splice_opensslConfig
	_here_opensslConfig_legacy | sudo -n tee /etc/ssl/openssl_legacy.cnf > /dev/null 2>&1

    if ! sudo -n grep 'openssl_legacy' /etc/ssl/openssl.cnf > /dev/null 2>&1
    then
        sudo -n cp -f /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf.orig
        echo '


.include = /etc/ssl/openssl_legacy.cnf

' | sudo -n cat /etc/ssl/openssl.cnf.orig - | sudo -n tee /etc/ssl/openssl.cnf > /dev/null 2>&1
    fi

    true
}
# WARNING: Forces all workflows to use this specialized function by default . Beware the possibility of external assumptions breaking very long build jobs.
#_getMinimal_cloud() {
    #_getMinimal_cloud_ubDistBuild_noBoot
#}







