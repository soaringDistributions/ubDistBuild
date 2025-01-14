#Override (Program).


# Attempts to reduce adding the necessary Debian packages, from ~5minutes , to much less . However, in practice, '_getMinimal_cloud' , is already very minimal.
# Relies on several assumptions:
#  _setupUbiquitous   has definitely always already been called
#  apt-fast   either is or is not available, hardcoded




_getMinimal_cloud_ubDistBuild_backend() {
    _messagePlain_probe "$@"
    sudo -n env XZ_OPT="-T0" DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -q --install-recommends -y "$@"
}

_getMinimal_cloud_ubDistBuild() {
    echo 'APT::AutoRemove::RecommendsImportant "true";
APT::AutoRemove::SuggestsImportant "true";' | _getMost_backend tee /etc/apt/apt.conf.d/99autoremove-recommends > /dev/null

    #dpkg --add-architecture i386
    #apt-get update
    #libc6:i386 lib32z1
    
    _getMinimal_cloud_ubDistBuild_backend --reinstall wget

    ##xz btrfs-tools grub-mkstandalone mkfs.vfat mkswap mmd mcopy mksquashfs
    #gpg pigz curl gdisk lz4 mawk jq gawk build-essential autoconf pkg-config bsdutils findutils patch tar gzip bzip2 sed lua-lpeg axel aria2 gh rsync pv expect libfuse2 udftools debootstrap cifs-utils dos2unix xxd debhelper p7zip nsis jp2a btrfs-progs btrfs-compsize zstd zlib1g coreutils util-linux kpartx openssl growisofs udev gdisk parted bc e2fsprogs xz-utils libreadline8 mkisofs genisoimage byobu xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools fdisk cloud-guest-utils
    ##dnsutils bind9-dnsutils bison libelf-dev elfutils flex libncurses-dev libudev-dev dwarves pahole cmake sockstat liblinear4 liblua5.3-0 nmap nmap-common socat dwarves pahole libssl-dev cpio libgtk2.0-0 libwxgtk3.0-gtk3-0v5 wipe iputils-ping nilfs-tools python3 sg3-utils cryptsetup php
    ##qemu-system-x86
    _getMinimal_cloud_ubDistBuild_backend gpg pigz curl gdisk lz4 mawk jq gawk build-essential autoconf pkg-config bsdutils findutils patch tar gzip bzip2 sed lua-lpeg axel aria2 gh rsync pv expect libfuse2 udftools debootstrap cifs-utils dos2unix xxd debhelper p7zip nsis jp2a btrfs-progs btrfs-compsize zstd zlib1g coreutils util-linux kpartx openssl growisofs udev gdisk parted bc e2fsprogs xz-utils libreadline8 mkisofs genisoimage byobu xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools fdisk cloud-guest-utils

    sudo -n env XZ_OPT="-T0" DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove --autoremove -y plasma-discover
}
# WARNING: Forces all workflows to use this specialized function by default . Beware the possibility of external assumptions breaking very long build jobs.
#_getMinimal_cloud() {
    #_getMinimal_cloud_ubDistBuild
#}





