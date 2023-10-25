
_test_prog() {
	_getDep pv

	_wantGetDep lsblk

	_wantGetDep unsquashfs
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
	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL-FileManager\command" /v "" /d "wslg.exe -d ubdist ~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap dolphin \"%V\"" /f

	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL-FileManager" /v "" /d "Open with ubdistWSL-FileManager" /f
	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL-FileManager\command" /v "" /d "wslg.exe -d ubdist ~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap dolphin \"%V\"" /f


	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL" /v "" /d "Open with ubdistWSL" /f
	reg add "HKEY_CLASSES_ROOT\Directory\shell\OpenWith_ubdistWSL\command" /v "" /d "wsl.exe -d ubdist" /f

	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL" /v "" /d "Open with ubdistWSL" /f
	reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWith_ubdistWSL\command" /v "" /d "wsl.exe -d ubdist" /f

	
	local currentMSWPath_associate
	currentMSWPath_associate=$(cygpath -w "$scriptLib"/support/MSW/associate.bat)


	# May be unusual. Unlike other apps, usability of native MSW equivalent for gEDA apps may not be expected.
	cmd /c "$currentMSWPath_associate" geda.schematic .sch gschem
	cmd /c "$currentMSWPath_associate" geda.pcb .pcb /usr/bin/pcb
	cmd /c "$currentMSWPath_associate" geda.fp .fp /usr/bin/pcb




	

	_messagePlain_probe_cmd _self_gitMad

	sleep 5
}

_setup_uninstall() {
	true

	#_uninstall_vm-wsl2
}


