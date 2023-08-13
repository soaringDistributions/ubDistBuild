
_test_prog() {
	_getDep pv
}


#_setup_install() {
	#local currentBackupDir=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"
	
	#if [[ "$1" != "" ]] && [[ ! -e "$currentBackupDir" ]]
	#then
		#_messagePlain_bad 'fail: bad: invalid: missing: parameter: "$1": '"$currentBackupDir"
		#_messageFAIL
		#_stop 1
		#return 1
	#fi
	
	#_install_wsl2 "$@"
    #_install_vm-wsl2 "$@"
#}

#_setup_uninstall() {
	#_uninstall_vm-wsl2
#}


