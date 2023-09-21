
_hash_rm() {
    rm -f "$scriptLocal"/_hash-ubdistBuildExe.txt > /dev/null 2>&1
    rm -f "$scriptLocal"/_hash-ubdist.txt > /dev/null 2>&1
}

# WARNING: CAUTION: Do NOT change correspondence between line number and hash ! Intended for automatic verification of distributed and end point integrity traceable back to Git repository public record !
_hash_file() {
    _messageNormal '_hash_file: '"$2"
    
    local currentListName="$1"
    local currentFileName="$2"
    local currentFilePath="$3"
    shift
    shift
    shift
    
    echo "$currentFileName" | tee -a "$scriptLocal"/_hash-"$currentListName".txt

    if [[ "$currentFileName" == *."iso" ]] || [[ "$currentFileName" == *."ISO" ]] || [[ "$currentFilePath" == *."iso" ]] || [[ "$currentFilePath" == *."ISO" ]]
    then
        echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(wc -c "$currentFilePath" | cut -f1 -d\ | tr -dc '0-9')' / 2048'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    else
        echo "openssl dgst -whirlpool -binary | xxd -p -c 256" | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    fi
    if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        cat "$currentFilePath" | "$@" | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    else
        cat "$currentFilePath" | "$@" | openssl dgst -whirlpool -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    fi

    if [[ "$currentFileName" == *."iso" ]] || [[ "$currentFileName" == *."ISO" ]] || [[ "$currentFilePath" == *."iso" ]] || [[ "$currentFilePath" == *."ISO" ]]
    then
        echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(wc -c "$currentFilePath" | cut -f1 -d\ | tr -dc '0-9')' / 2048'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    else
        echo "openssl dgst -sha3-512 -binary | xxd -p -c 256" | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    fi
    if [[ "$skimfast" == "true" ]]
    then
        cat "$currentFilePath" | "$@" | openssl dgst -sha3-512 -binary | xxd -p -c 256 | tee -a "$scriptLocal"/_hash-"$currentListName".txt
    else
        echo
    fi
    
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
    _hash_file ubdist vm-live.iso "$scriptLocal"/vm-live.iso cat
}



