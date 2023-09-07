
_hash_rm() {
    rm -f "$scriptLocal"/_hash-ubdistBuildExe.txt > /dev/null 2>&1
    rm -f "$scriptLocal"/_hash-ubdist.txt > /dev/null 2>&1
}

_hash_file() {
    _messageNormal '_hash_file: '"$2"
    
    local currentListName="$1"
    local currentFileName="$2"
    local currentFilePath="$3"
    shift
    shift
    shift
    
    echo "$currentFileName" | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    echo "openssl dgst -whirlpool -binary | xxd -p -c 256" | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        cat "$currentFilePath" | "$@" | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    else
        cat "$currentFilePath" | "$@" | openssl dgst -whirlpool -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    fi
    echo "openssl dgst -sha3-512 -binary | xxd -p -c 256" | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    cat "$currentFilePath" | "$@" | openssl dgst -sha3-512 -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    echo | tee -a "$scriptLocal"/_hash-"$currentListName".txt
}



_hash_ubDistBuildExe() {
    _hash_file ubDistBuildExe ubDistBuild.exe "$scriptAbsoluteFolder"/../ubDistBuild.exe cat
}


_hash_img() {
    _hash_file ubdist vm.img "$scriptLocal"/vm.img cat
}

_hash_rootfs() {
    _hash_file ubdist package_rootfs.tar "$scriptLocal"/package_rootfs.tar.flx lz4 -d -c
}

_hash_live() {
    _hash_rootfs ubdist vm-live.iso "$scriptLocal"/vm-live.iso cat
}



