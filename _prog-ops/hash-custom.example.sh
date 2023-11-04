
_hash_rm() {
    rm -f "$scriptLocal"/_hash-ubdistBuildExe.txt > /dev/null 2>&1
    rm -f "$scriptLocal"/_hash-ubdist.txt > /dev/null 2>&1
}

# WARNING: Legacy. Reference example.
#  NOTICE: Not recommended for new designs. No further producton use.
# WARNING: CAUTION: Do NOT change correspondence between line number and hash ! Intended for automatic verification of distributed and end point integrity traceable back to Git repository public record !
_hash_file_sequence() {
    _custom_splice_opensslConfig
    
    _start
    
    _messageNormal '_hash_file: '"$2"
    
    local currentListName="$1"
    local currentFileName="$2"
    local currentFilePath="$3"
    shift
    shift
    shift
    
    echo "$currentFileName" >> "$scriptLocal"/_hash-"$currentListName".txt

    if [[ "$currentFileName" == *."iso" ]] || [[ "$currentFileName" == *."ISO" ]] || [[ "$currentFilePath" == *."iso" ]] || [[ "$currentFilePath" == *."ISO" ]]
    then
        echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(cat "$currentFilePath" | "$@" | wc -c | cut -f1 -d\ | tr -dc '0-9')' / 2048'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    else
        #echo "openssl dgst -whirlpool -binary | xxd -p -c 256" >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
        echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$currentFilePath" | "$@" | wc -c | cut -f1 -d\ | tr -dc '0-9')' / 1048576'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    fi
    if [[ -e "/etc/ssl/openssl_legacy.cnf" ]]
    then
        cat "$currentFilePath" | "$@" | env OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf" openssl dgst -whirlpool -binary | xxd -p -c 256 >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt &
    else
        cat "$currentFilePath" | "$@" | openssl dgst -whirlpool -binary | xxd -p -c 256 >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt &
    fi

    if [[ "$currentFileName" == *."iso" ]] || [[ "$currentFileName" == *."ISO" ]] || [[ "$currentFilePath" == *."iso" ]] || [[ "$currentFilePath" == *."ISO" ]]
    then
        echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(cat "$currentFilePath" | "$@" | wc -c | cut -f1 -d\ | tr -dc '0-9')' / 2048'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    else
        #echo "openssl dgst -sha3-512 -binary | xxd -p -c 256" >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
        echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$currentFilePath" | "$@" | wc -c | cut -f1 -d\ | tr -dc '0-9')' / 1048576'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    fi
    #if [[ "$skimfast" == "true" ]]
    #then
        #echo >> "$safeTmp"/_hash-"$currentListName"-sha3.txt &
    #else
        cat "$currentFilePath" | "$@" | openssl dgst -sha3-512 -binary | xxd -p -c 256 >> "$safeTmp"/_hash-"$currentListName"-sha3.txt &
    #fi

    wait
    cat "$safeTmp"/_hash-"$currentListName"-whirlpool.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    cat "$safeTmp"/_hash-"$currentListName"-sha3.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo >> "$scriptLocal"/_hash-"$currentListName".txt

    cat "$scriptLocal"/_hash-"$currentListName".txt

    _stop
}

_hash_file() {
    "$scriptAbsoluteLocation" _hash_file_sequence "$@"
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



_hash_img-stream() {
    _custom_splice_opensslConfig
    
    _start
    
    
    [[ -e "/etc/ssl/openssl_legacy.cnf" ]] && export OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf"
    
    
    local currentListName=ubdist-img
    local currentFileName=vm.img
    local currentFilePath=/dev/stdin
    
    _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$1" "package_image.tar.flx" 2> /dev/null | _get_extract_ubDistBuild-tar --extract ./vm.img --to-stdout | \
tee >( wc -c /dev/stdin | cut -f1 -d\ | tr -dc '0-9' > "$safeTmp"/.tmp-currentFileBytes ) | \
tee >( openssl dgst -whirlpool -binary | xxd -p -c 256 > "$safeTmp"/.tmp-whirlpool ) | \
( [[ "$skimfast" != "true" ]] && openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$safeTmp"/.tmp-sha3 )

    wait
    
    echo "$currentFileName" >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 1048576'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    cat "$safeTmp"/.tmp-whirlpool >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    
    echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 1048576'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    
    if [[ "$skimfast" != "true" ]]
    then
        cat "$safeTmp"/.tmp-sha3 >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    else
        echo  >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    fi
    
    
    wait
    cat "$safeTmp"/_hash-"$currentListName"-whirlpool.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    cat "$safeTmp"/_hash-"$currentListName"-sha3.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo >> "$scriptLocal"/_hash-"$currentListName".txt

    cat "$scriptLocal"/_hash-"$currentListName".txt
    

    _stop
}

_hash_rootfs-stream() {
    _custom_splice_opensslConfig
    
    _start
    
    
    [[ -e "/etc/ssl/openssl_legacy.cnf" ]] && export OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf"
    
    
    local currentListName=ubdist-rootfs
    local currentFileName=package_rootfs.tar
    local currentFilePath=/dev/stdin
    
    _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$1" "package_rootfs.tar.flx" 2> /dev/null | lz4 -d -c | \
tee >( wc -c /dev/stdin | cut -f1 -d\ | tr -dc '0-9' > "$safeTmp"/.tmp-currentFileBytes ) | \
tee >( openssl dgst -whirlpool -binary | xxd -p -c 256 > "$safeTmp"/.tmp-whirlpool ) | \
( [[ "$skimfast" != "true" ]] && openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$safeTmp"/.tmp-sha3 )

    wait
    
    echo "$currentFileName" >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 1048576'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    cat "$safeTmp"/.tmp-whirlpool >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    
    echo 'dd if=./'"$currentFileName"' bs=1048576 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 1048576'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    
    if [[ "$skimfast" != "true" ]]
    then
        cat "$safeTmp"/.tmp-sha3 >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    else
        echo  >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    fi
    
    
    wait
    cat "$safeTmp"/_hash-"$currentListName"-whirlpool.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    cat "$safeTmp"/_hash-"$currentListName"-sha3.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo >> "$scriptLocal"/_hash-"$currentListName".txt

    cat "$scriptLocal"/_hash-"$currentListName".txt
    

    _stop
}

_hash_live-stream() {
    _custom_splice_opensslConfig
    
    _start
    
    
    [[ -e "/etc/ssl/openssl_legacy.cnf" ]] && export OPENSSL_CONF="/etc/ssl/openssl_legacy.cnf"
    
    
    local currentListName=ubdist-live
    local currentFileName=vm-live.iso
    local currentFilePath=/dev/stdin
    
    _wget_githubRelease_join-stdout "soaringDistributions/ubDistBuild" "$1" "vm-live.iso" 2> /dev/null | \
tee >( wc -c /dev/stdin | cut -f1 -d\ | tr -dc '0-9' > "$safeTmp"/.tmp-currentFileBytes ) | \
tee >( openssl dgst -whirlpool -binary | xxd -p -c 256 > "$safeTmp"/.tmp-whirlpool ) | \
( [[ "$skimfast" != "true" ]] && openssl dgst -sha3-512 -binary | xxd -p -c 256 > "$safeTmp"/.tmp-sha3 )

    wait
    
    echo "$currentFileName" >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 2048'"'"' ) status=progress | openssl dgst -whirlpool -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    cat "$safeTmp"/.tmp-whirlpool >> "$safeTmp"/_hash-"$currentListName"-whirlpool.txt
    
    
    echo 'dd if=./'"$currentFileName"' bs=2048 count=$(bc <<< '"'"$(cat "$safeTmp"/.tmp-currentFileBytes)' / 2048'"'"' ) status=progress | openssl dgst -sha3-512 -binary | xxd -p -c 256' >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    
    if [[ "$skimfast" != "true" ]]
    then
        cat "$safeTmp"/.tmp-sha3 >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    else
        echo  >> "$safeTmp"/_hash-"$currentListName"-sha3.txt
    fi
    
    
    wait
    cat "$safeTmp"/_hash-"$currentListName"-whirlpool.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    cat "$safeTmp"/_hash-"$currentListName"-sha3.txt >> "$scriptLocal"/_hash-"$currentListName".txt
    
    echo >> "$scriptLocal"/_hash-"$currentListName".txt

    cat "$scriptLocal"/_hash-"$currentListName".txt
    

    _stop
}


_hash_ubdist-fast() {
    export FORCE_AXEL=6
    export MANDATORY_HASH="true"
    
    rm -f "$scriptLocal"/_hash-ubdist-img.txt
    rm -f "$scriptLocal"/_hash-ubdist-rootfs.txt
    rm -f "$scriptLocal"/_hash-ubdist-live.txt
          
    local currentPID_1
    "$scriptAbsoluteLocation" _hash_img-stream "$@" &
    currentPID_1="$!"
    
    local currentPID_2
    "$scriptAbsoluteLocation" _hash_rootfs-stream "$@" &
    currentPID_2="$!"
    
    local currentPID_3
    "$scriptAbsoluteLocation" _hash_live-stream "$@" &
    currentPID_3="$!"
    
    wait "$currentPID_1"
    wait "$currentPID_2"
    wait "$currentPID_3"
    wait
    
    rm -f "$scriptLocal"/_hash-ubdist.txt
    
    cat "$scriptLocal"/_hash-ubdist-img.txt >> "$scriptLocal"/_hash-ubdist.txt
    cat "$scriptLocal"/_hash-ubdist-rootfs.txt >> "$scriptLocal"/_hash-ubdist.txt
    cat "$scriptLocal"/_hash-ubdist-live.txt >> "$scriptLocal"/_hash-ubdist.txt
    
    echo
    
    cat "$scriptLocal"/_hash-ubdist.txt
}













