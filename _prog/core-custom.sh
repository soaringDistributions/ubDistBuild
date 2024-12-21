






_zSpecial_qemu-before_noBoot_sequence_prog() {
	# A rather complicated issue with VirtualBox vboxdrv kernel module.
	# Module vboxdrv build may be attempted for running kernel of ChRoot host.
	# Sevice vboxdrv will attempt to build, may timeout in ~5 minutes (due to slow qemu without kvm), fail, every boot.
	# Since this should not take much time or power for modern CPUs, and should only affect the ability run VirtualBox guests on first boot (ie. does not affect guest additions), this is expected at most a minor inconvenience.
	
	# sudo -n systemctl status vboxdrv
	echo '#!/usr/bin/env bash' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n update-grub' >> "$hostToGuestFiles"/cmd.sh
	echo '_detect_process_compile() {
	pgrep cc1 && return 0
	pgrep apt && return 0
	pgrep dpkg && return 0
	top -b -n1 | tail -n+8 | head -n1 | grep packagekit && return 0
	sudo -n systemctl status vboxdrv | grep loading && return 0
	return 1
} ' >> "$hostToGuestFiles"/cmd.sh
	
	# Commenting this may reduce first iteration 'currentIterationWait' by ~120s , possibly improving opportunity to successfully compile through slow qemu without kvm.
	# If uncommented, any indefinite delay in '_detect_process_compile' may cause failure.
	#echo 'while _detect_process_compile && sleep 27 && _detect_process_compile && sleep 27 && _detect_process_compile ; do sleep 27 ; done' >> "$hostToGuestFiles"/cmd.sh
	
	echo 'sleep 15' >> "$hostToGuestFiles"/cmd.sh
	#echo '! sudo -n lsmod | grep -i vboxdrv && sudo -n /sbin/vboxconfig' >> "$hostToGuestFiles"/cmd.sh
	echo 'sleep 75' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n lsmod | cut -f1 -d\  | sudo -n tee /lsmodReport' >> "$hostToGuestFiles"/cmd.sh
	#echo '[[ ! -e /kded5-done ]] && kded5 --check' >> "$hostToGuestFiles"/cmd.sh
	#echo '[[ ! -e /kded5-done ]] && sleep 90' >> "$hostToGuestFiles"/cmd.sh

	echo '[[ ! -e /FW-done ]] && cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop | sudo -n tee /cfgFW.log ; cd' >> "$hostToGuestFiles"/cmd.sh
	echo '[[ ! -e /FW-done ]] && cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop | sudo -n tee /cfgFW.log ; cd' >> "$hostToGuestFiles"/cmd.sh

	#echo '[[ ! -e /kded5-done ]] && kded5 --check' >> "$hostToGuestFiles"/cmd.sh
	#echo '( [[ ! -e /kded5-done ]] || [[ ! -e /FW-done ]] ) && sleep 420' >> "$hostToGuestFiles"/cmd.sh
    echo '( [[ ! -e /FW-done ]] ) && sleep 420' >> "$hostToGuestFiles"/cmd.sh
	#echo 'echo | sudo -n tee /kded5-done' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo | sudo -n tee /FW-done' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n poweroff' >> "$hostToGuestFiles"/cmd.sh
}

# ATTENTION: Override with 'ops.sh' or similar.
_zSpecial_qemu-before_noBoot_sequence() {
	_messagePlain_nominal 'init: _zSpecial_qemu-before_noBoot_sequence'
	_start
	
	
	if [[ "$qemuHeadless" == "true" ]] || [[ "$qemuBootOnce" == "true" ]] || [[ "$qemu_custom" == "true" ]]
	then
		#_commandBootdisc
		
		! _prepareBootdisc && _messageFAIL
		
		cp "$scriptAbsoluteLocation" "$hostToGuestFiles"/
		"$scriptBin"/.ubrgbin.sh _ubrgbin_cpA "$scriptBin" "$hostToGuestFiles"/_bin
		
		
		_zSpecial_qemu-before_noBoot_sequence_prog "$@"
		
		
		
		! _writeBootdisc && _messageFAIL
	fi
	
	
	
	[[ "$qemuHeadless" == "true" ]] && qemuArgs+=(-nographic)
	
	
	qemuArgs+=(-usb)
	
	# *nested* x64 hardware vt
	#qemuArgs+=(-cpu host)
	
	# CPU >2 may force more compatible SMP kernel, etc.
	#qemuArgs+=(-smp 2)
	local hostThreadCount
	hostThreadCount=$(cat /proc/cpuinfo | grep MHz | wc -l | tr -dc '0-9')
	qemuArgs+=(-smp "$hostThreadCount")
	
	
	
	# vm.img
	qemuUserArgs+=(-drive format=raw,file="$scriptLocal"/vm.img)
	
	# LiveCD
	#qemuUserArgs+=(-drive file="$ub_override_qemu_livecd",media=cdrom)
	
	# LiveUSB, hibernate/bup, etc
	#qemuUserArgs+=(-drive format=raw,file="$ub_override_qemu_livecd_more")
	
	# Installation CD image.
	#qemuUserArgs+=(-drive file="$scriptLocal"/netinst.iso,media=cdrom -boot c)
	
	
	
	
	[[ -e "$hostToGuestISO" ]] && qemuUserArgs+=(-drive file="$hostToGuestISO",media=cdrom)
	
	# Boot from whichever emulated disk connected ('-boot c' for emulated disc 'cdrom')
	qemuUserArgs+=(-boot d)
	
	
	
	
	# Must have at least 4096MB for 'livecd' , unless even larger memory allocation has been configured .
	# Must have >=8704MB for MSW10 or MSW11 . GNU/Linux may eventually follow with similar expectations.
	# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
	#  '7 GB of RAM memory'
	#  '14 GB of SSD disk space'
	#qemuUserArgs+=(-m "8704")
	#qemuUserArgs+=(-m "3072")
	#qemuUserArgs+=(-m "1664")
	_zSpecial_qemu_memory "$@"
	
	
	[[ "$qemuUserArgs_netRestrict" == "" ]] && qemuUserArgs_netRestrict="n"
	qemuUserArgs+=(-net nic,model=rtl8139 -net user,restrict="$qemuUserArgs_netRestrict")
	#,smb="$sharedHostProjectDir"
	
	
	qemuArgs+=(-device usb-tablet)
	
	
	#qemuArgs+=(-device ich9-intel-hda -device hda-duplex)
	
	# https://github.com/elisa-tech/meta-elisa/issues/23
	# https://wiki.qemu.org/ChangeLog/6.0
	# qemuArgs+=(-show-cursor)
	if [[ $(_qemu_system_x86_64 -version | grep version | sed 's/.*version\ //' | sed 's/\ .*//' | cut -f1 -d\. | tr -dc '0-9') -lt "6" ]]
	then
		qemuArgs+=(-show-cursor)
	fi
	
	
	#qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=off)
	##qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=on)
	
	qemuArgs+=(-device qxl-vga)
	
	#qemuArgs+=(-vga cirrus)
	
	#qemuArgs+=(-vga std)
	
	
	
	# hardware vt
	if _testQEMU_hostArch_x64_hardwarevt
	then
		# Apparently, qemu kvm, can be unreliable if nested (eg. within VMWare Workstation VM).
		#[[ "$qemuHeadless" == "true" ]] || 
		_messagePlain_good 'found: kvm'
		if [[ "$qemuNoKVM" == "true" ]] || [[ "$qemuNoKVM" != "false" ]]
		then
			_messagePlain_good 'ignored: kvm'
		else
			qemuArgs+=(-machine accel=kvm)
		fi
	else
		_messagePlain_warn 'missing: kvm'
	fi
	
	
	# https://www.kraxel.org/repos/jenkins/edk2/
	# https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-20200515.1447.g317d84abe3.noarch.rpm
	if [[ -e "$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd ]] && [[ -e "$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd ]]
	then
		qemuArgs+=(-drive if=pflash,format=raw,readonly,file="$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd -drive if=pflash,format=raw,file="$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd)
	elif [[ -e /usr/share/OVMF/OVMF_CODE.fd ]]
	then
		qemuArgs+=(-bios /usr/share/OVMF/OVMF_CODE.fd)
	fi
	
	qemuArgs+=("${qemuSpecialArgs[@]}" "${qemuUserArgs[@]}")
	
	_messagePlain_probe _qemu_system_x86_64 "${qemuArgs[@]}"
	
	
	local currentExitStatus
	
	ls -l /dev/kvm

	if [[ "$qemuHeadless" != "true" ]]
	then
		_qemu_system_x86_64 "${qemuArgs[@]}"
		currentExitStatus="$?"
	else
		_qemu_system_x86_64 "${qemuArgs[@]}" | tr -dc 'a-zA-Z0-9\n'
		currentExitStatus=${PIPESTATUS[0]}
		#currentExitStatus="$?"
	fi
	
	
	_zSpecial_qemu_chroot "$@"
	
	
	if [[ -e "$instancedVirtDir" ]] && ! _safeRMR "$instancedVirtDir"
	then
		_messageFAIL
	fi
	
	_stop "$currentExitStatus"
}
_zSpecial_qemu-before_noBoot() {
	if ! "$scriptAbsoluteLocation" _zSpecial_qemu-before_noBoot_sequence "$@"
	then
		_stop 1
	fi
	return 0
}


# ATTENTION: NOTICE: Maintenance - this function is nearly identical to '_create_ubDistBuild-bootOnce-before_noBoot-qemu_sequence', but calls a different chain of '_zSpecial_qemu' related functions, mostly if not entirely to control 'cmd.sh' , etc .
_create_ubDistBuild-bootOnce-before_noBoot-qemu_sequence() {
	! type qemu-system-x86_64 > /dev/null 2>&1 && _stop 1

	local currentExitStatus
	
	( [[ "$qemuHeadless" != "false" ]] || [[ "$DISPLAY" == "" ]] ) && export qemuHeadless="true"
	
	[[ "$qemuXvfb" == "true" ]] && export qemuHeadless="false"
	
	if [[ "$qemuXvfb" == "true" ]]
	then
		local currentPID_xvfb
		Xvfb :30 > /dev/null 2>&1 &
		currentPID_xvfb="$!"
		sleep 1
		export DISPLAY=":30"
	fi
	
	
	export qemuBootOnce="true"
	
	local currentPID
	local currentPID_qemu
	local currentNumProc
	
	"$scriptAbsoluteLocation" _zSpecial_qemu-before_noBoot "$@" &
	currentPID="$!"
	sleep 6
	currentPID_qemu=$(ps -ef --sort=start_time | grep qemu | grep -v grep | tr -dc '0-9 \n' | tail -n1 | sed 's/\ *//' | cut -f1 -d\  )
	
	
	##disown -h $currentPID
	#disown -a -h -r
	#disown -a -r
	
	# Up to 700s per kernel (ie. modules), plus 500s, total of 1147s for one kernel, 1749s to wait for three kernels.
	_messagePlain_nominal 'wait: 9000s'
	local currentIterationWait
	currentIterationWait=0
	pgrep qemu-system
	pgrep qemu
	ps -p "$currentPID"
	while [[ "$currentIterationWait" -lt 9000 ]] && ( pgrep qemu-system > /dev/null 2>&1 || pgrep qemu > /dev/null 2>&1 || ps -p "$currentPID" > /dev/null 2>&1 )
	do
		if ( [[ "$qemuXvfb" == "true" ]] && ( [[ "$currentIterationWait" -le 320 ]] && [[ $(bc <<< "$currentIterationWait % 5") == 0 ]] ) || [[ $(bc <<< "$currentIterationWait % 30") == 0 ]] )
		then
			mkdir -p "$scriptLocal"/analysis/screenshots
			#xwd -root -silent | convert xwd:- png:"$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".png
			xwd -root -silent | convert xwd:- -quality 35 jpg:"$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".jpg
			#jp2a --background=dark --colors --width=280 "$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".jpg
		fi
		
		
		
		sleep 1
		let currentIterationWait=currentIterationWait+1
	done
	_messagePlain_probe_var currentIterationWait
	[[ "$currentIterationWait" -ge 9000 ]] && _messagePlain_bad 'bad: fail: bootdisc: poweroff' && currentExitStatus=1
	sleep 27
	
	
	# May not be necessary. Theoretically redundant.
	local currentStopJobs
	currentStopJobs=$(jobs -p -r 2> /dev/null)
	_messagePlain_probe_var currentStopJobs
	[[ "$currentStopJobs" != "" ]] && kill "$currentStopJobs"
	
	#disown -h $currentPID
	disown -a -h -r
	disown -a -r
	
	
	currentNumProc=$(ps -e | grep qemu-system-x86 | wc -l | tr -dc '0-9')
	_messagePlain_probe_var currentNumProc
	_messagePlain_probe '$$= '$$
	_messagePlain_probe_var currentPID
	kill "$currentPID"
	_messagePlain_probe_var currentPID_qemu
	kill "$currentPID_qemu"
	sleep 1
	
	if [[ "$currentNumProc" == "1" ]]
	then
		pkill qemu-system-x86
		sleep 3
		pkill -KILL qemu-system-x86
		sleep 3
	fi
	
	
	echo
	
	if [[ "$qemuXvfb" == "true" ]]
	then
		kill "$currentPID_xvfb"
		sleep 3
		kill -KILL "$currentPID_xvfb"
		pkill Xvfb
	fi
	
	rm -f "$scriptLocal"/FAIL_bootOnce
	if [[ "$currentExitStatus" == "1" ]]
	then
		echo ${FUNCNAME[0]} > "$scriptLocal"/FAIL_bootOnce
		return 1
	fi
	return 0
}















_create_ubDistBuild-bootOnce-before_noBoot() {
	_messageNormal '##### init: _create_ubDistBuild-bootOnce-before_noBoot'
	
	
	#_messageNormal 'chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#_chroot systemctl set-default graphical.target
    _chroot rm -f /FW-done
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	


	
	
	_messageNormal 'qemu'
	
	local currentIteration
	local currentIterationTotal
	currentIterationTotal=2
	# May need 3 iterations, especially if "package_kde" is from a previous version of Debian Stable (ie. if KDE upgrade must happen automatically).
	#currentIterationTotal=3
	[[ "$skimfast" == "true" ]] && currentIterationTotal=1

	#for currentIteration in $(seq 1 3)
	for currentIteration in $(seq 1 "$currentIterationTotal")
	do
		_messagePlain_probe_var currentIteration
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-qemu_sequence "$@"
		then
			_messageFAIL
		fi
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-fsck_sequence "$@"
		then
			_messageFAIL
		fi
	done
	
	
	_messageNormal '##### _create_ubDistBuild-bootOnce-before_noBoot: chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# https://stackoverflow.com/questions/8579330/appending-to-crontab-with-a-shell-script-on-ubuntu
	
    # WARNING: CAUTION: Do NOT enable without both ensuring previous crontab entries remain present (eg. 'bootdisc... rootnix.sh') and also ensuring crontab does not accumulate duplicate entries.
    # Normally, this command is only run once, only after the first boot of upstream 'ubdist' , and the crontab entry should remain present for any subsequent installation/enabling/disabling/etc of NVIDIA drivers.
    #  The '_get_nvidia.sh' script is resliliently 'smart', detecting such situations as NVIDIA drivers already installed, local driver installation package available, NVIDIA hardware not present, etc.
    #  This same script is used during checks by 'mirage335KernelBuild' operated by "Soaring Distributions LLC", thus CI testing of both its resilience and upstream kernels happens regularly, ensuring good maintenance as needed.
	#( _chroot crontab -l ; echo '@reboot /root/_get_nvidia.sh _autoinstall > /var/log/_get_nvidia.log 2>&1' ) | _chroot crontab '-'
	#_nouveau_disable_procedure
	
	
	#sudo -n mkdir -p "$globalVirtFS"/root/core_rG/flipKey/_local
	#sudo -n cp -f "$scriptLib"/setup/rootGrab/_rootGrab.sh "$globalVirtFS"/root/_rootGrab.sh
	#sudo -n chmod 700 "$globalVirtFS"/root/_rootGrab.sh
	#sudo -n cp -f "$scriptLib"/flipKey/flipKey "$globalVirtFS"/root/core_rG/flipKey/flipKey
	#sudo -n chmod 700 "$globalVirtFS"/root/core_rG/flipKey/flipKey
	
	#! _chroot /root/_rootGrab.sh _hook && _messageFAIL
	
	
	
	_chroot dpkg -l | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
	
	
	_chroot rmdir /var/lib/docker/runtimes
	
	echo | sudo -n tee "$globalVirtFS"/regenerate > /dev/null
	
	echo | sudo -n tee "$globalVirtFS"/regenerate_rootGrab > /dev/null
	
	
	# WARNING: Important. May drastically reduce image size, especially if large temporary files (ie. apt cache) have been used. *Very* compressible zeros.
	# https://fedoraproject.org/wiki/Changes/BtrfsTransparentCompression
	#  'btrfs property' 'Unsetting it is...tricky' 'doesn't unset compression, it prevents the compress mount option from working'
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
	
	# Run only once. If used two or more times, apparently may decrease available storage by ~1GB .
	# Apparently, if defrag is run once with compression, rootfs usage may reduce from ~6.6GB to ~5.9GB . However, running again may expand usage back to ~6.6GB.
	# https://github.com/kdave/btrfs-progs/issues/184
	_chroot btrfs filesystem defrag -r -czstd /
	
	_messagePlain_nominal 'chroot: report: df'
	_chroot df -h /
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	return 0
}




