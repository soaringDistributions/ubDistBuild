
; ATTRIBUTION - May be largely attributable to ChatGPT-4/copilot used by mirage335 .
; ATTRIBUTION - https://nsis.sourceforge.io/Sample_installation_script_for_an_application
; ATTRIBUTION - https://nsis.sourceforge.io/A_simple_installer_with_start_menu_shortcut_and_uninstaller
; ATTRIBUTION - https://nsis.sourceforge.io/Embedding_other_installers
; ATTRIBUTION - https://stackoverflow.com/questions/3265141/executing-batch-file-in-nsis-installer





RequestExecutionLevel admin




SilentInstall normal
LicenseData "..\..\license-installer.txt"

Name "ubDistBuild"
Icon ".\icon\ubdist.ico"
OutFile "..\..\..\ubDistBuild.exe"






;/SOLID
SetCompressor /FINAL lzma


Page license
;Page directory
Page instfiles

;https://github.com/soaringDistributions/ubDistBuild
!define APPNAME "ubDistBuild"
!define COMPANYNAME "ubDistBuild"
!define DESCRIPTION "ubDistBuild"
!define HELPURL "https://github.com/soaringDistributions/ubDistBuild"
!define UPDATEURL "https://github.com/soaringDistributions/ubDistBuild"
!define ABOUTURL "https://github.com/soaringDistributions/ubDistBuild"
!define INSTALLSIZE 2800000
;!define INSTALLSIZE 4500000


Section "Install"
  SetShellVarContext all

  ; Generate a random alphanumeric string
  System::Call 'KERNEL32::GetTickCount()i.r0'
  System::Call 'ADVAPI32::CryptAcquireContext(i0,t""i0,i0,i0,i0)i.r1'
  System::Call 'ADVAPI32::CryptGenRandom(ir1,i10,i0)i'
  System::Call 'ADVAPI32::CryptReleaseContext(ir1,i0)i'
  IntCmp $0 0 0 +3
  IntOp $0 $0 * -1

  ;ATTENTION
  CreateDirectory "C:\core\infrastructure\ubDistBuild-backup-$0\_local"
  Rename "C:\core\infrastructure\ubDistBuild\_local\vm.img" "C:\core\infrastructure\ubDistBuild-backup-$0\_local\vm.img"
  Rename "C:\core\infrastructure\ubDistBuild\_local\vm-live.iso" "C:\core\infrastructure\ubDistBuild-backup-$0\_local\vm-live.iso"
  Rename "C:\core\infrastructure\ubDistBuild\_local\package_rootfs.tar" "C:\core\infrastructure\ubDistBuild-backup-$0\_local\package_rootfs.tar"

  RMDir /r "C:\core\infrastructure\ubDistBuild"
  ;RMDir /r /REBOOTOK "C:\core\infrastructure\ubDistBuild"

  SetOutPath "C:\core\infrastructure\ubDistBuild"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild\*"

  ;SetOutPath "C:\core\infrastructure\ubDistBuild\_local\ubcp"
  ;File /r "..\..\..\ubDistBuild-accessories\parts\ubcp\package_ubcp-core\ubcp\*"
  SetOutPath "C:\core\infrastructure\ubDistBuild\_local"
  File "..\..\..\ubDistBuild-accessories\integrations\ubcp\package_ubcp-core.7z"
  SetOutPath "$TEMP\ubDistBuild_bundle\7zip"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle\7zip\*"
  ;SetOutPath "C:\core\infrastructure\ubDistBuild\_lib\7zip"
  ;File "..\..\..\ubDistBuild-accessories\integrations\7zip\7zr.exe"
  #nsExec::ExecToLog '"C:\core\infrastructure\ubDistBuild\_lib\7zip\7zr.exe" x "C:\core\infrastructure\ubDistBuild\_local\package_ubcp-core.7z" -o"C:\core\infrastructure\ubDistBuild\_local\ubcp" -y'
  ; Extract to _local so the archive's top-level ubcp directory lands at the expected path
  nsExec::ExecToLog '"$TEMP\ubDistBuild_bundle\7zip\7zr.exe" x "C:\core\infrastructure\ubDistBuild\_local\package_ubcp-core.7z" -o"C:\core\infrastructure\ubDistBuild\_local" -y'
  Delete "C:\core\infrastructure\ubDistBuild\_local\package_ubcp-core.7z"

  ;ATTENTION
  Rename "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\vm.img" "C:\core\infrastructure\ubDistBuild\_local\vm.img"
  Rename "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\vm-live.iso" "C:\core\infrastructure\ubDistBuild\_local\vm-live.iso"
  Rename "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\package_rootfs.tar" "C:\core\infrastructure\ubDistBuild\_local\package_rootfs.tar"
  RMDir "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local"
  RMDir "C:\core\infrastructure\ubDistBuild-backup-uninstalled"

  ;ATTENTION
  Rename "C:\core\infrastructure\ubDistBuild-backup-$0\_local\vm.img" "C:\core\infrastructure\ubDistBuild\_local\vm.img"
  Rename "C:\core\infrastructure\ubDistBuild-backup-$0\_local\vm-live.iso" "C:\core\infrastructure\ubDistBuild\_local\vm-live.iso"
  Rename "C:\core\infrastructure\ubDistBuild-backup-$0\_local\package_rootfs.tar" "C:\core\infrastructure\ubDistBuild\_local\package_rootfs.tar"
  RMDir "C:\core\infrastructure\ubDistBuild-backup-$0\_local"
  RMDir "C:\core\infrastructure\ubDistBuild-backup-$0"


  Rename "C:\core\variant\ubdist_dummy" "C:\core\variant\ubdist_dummy-backup-$0"
  SetOutPath "C:\core\variant\ubdist_dummy"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubdist_dummy\*"

  Rename "C:\core\variant\ubdist_puddleJumper" "C:\core\variant\ubdist_puddleJumper-backup-$0"
  SetOutPath "C:\core\variant\ubdist_puddleJumper"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubdist_puddleJumper\*"


  SetShellVarContext all


  ;start /wait
  SetOutPath "$TEMP\ubDistBuild_bundle\usbip-win"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle\usbip-win\*"
  IfSilent +2
  ExecWait '"msiexec" /i "$TEMP\ubDistBuild_bundle\usbip-win\usbipd-win_5.1.0_x64.msi"'
  IfSilent 0 +2
  ExecWait '"msiexec" /i "$TEMP\ubDistBuild_bundle\usbip-win\usbipd-win_5.1.0_x64.msi" /passive /norestart'


  ;start /wait
  SetOutPath "$TEMP\ubDistBuild_bundle\wsl-usb-gui"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle\wsl-usb-gui\*"
  IfSilent +2
  ExecWait '"msiexec" /i "$TEMP\ubDistBuild_bundle\wsl-usb-gui\WSL-USB-5.7.0.msi"'
  IfSilent 0 +2
  ExecWait '"msiexec" /i "$TEMP\ubDistBuild_bundle\wsl-usb-gui\WSL-USB-5.7.0.msi" /passive /norestart'


  ;start /wait
  SetOutPath "$TEMP\ubDistBuild_bundle\vc_redist"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle\vc_redist\*"
  IfSilent +2
  ExecWait "$TEMP\ubDistBuild_bundle\vc_redist\vc_redist.x64.exe"
  IfSilent 0 +2
  ExecWait "$TEMP\ubDistBuild_bundle\vc_redist\vc_redist.x64.exe /install /passive /norestart"
  ;ExecWait "$TEMP\ubDistBuild_bundle\vc_redist\vc_redist.x64.exe /Q"


  ;;https://silentinstallhq.com/oracle-vm-virtualbox-6-1-silent-install-how-to-guide/
  ;;start /wait
  ;SetOutPath "$TEMP\ubDistBuild_bundle-adhoc\virtualbox"
  ;File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle-adhoc\virtualbox\*"
  ;IfSilent +2
  ;ExecWait "$TEMP\ubDistBuild_bundle-adhoc\virtualbox\VirtualBox-7.0.10-158379-Win.exe"
  ;IfSilent 0 +2
  ;ExecWait "$TEMP\ubDistBuild_bundle-adhoc\virtualbox\VirtualBox-7.0.10-158379-Win.exe --silent --ignore-reboot"


  ;start /wait
  SetOutPath "$TEMP\ubDistBuild_bundle-adhoc\qemu"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle-adhoc\qemu\*"
  IfSilent +2
  ExecWait "$TEMP\ubDistBuild_bundle-adhoc\qemu\qemu-w64-setup-20250422.exe"
  IfSilent 0 +2
  ExecWait "$TEMP\ubDistBuild_bundle-adhoc\qemu\qemu-w64-setup-20250422.exe /S"



  ;SetOutPath "C:\core\installations\filezilla_install"
  SetOutPath "C:\core\installations"
  File /r "..\..\..\ubDistBuild-accessories\parts\ubDistBuild_bundle\filezilla\*"


  ; ATTENTION: Startups may be copied again.
  CopyFiles "C:\_install_vm-wsl2-portForward.bat" "$SMSTARTUP"



  ExpandEnvStrings $5 %COMSPEC%
  ExecWait '"$5" /C "C:\core\infrastructure\ubDistBuild\_bin.bat" _setup_install $0'
  DetailPrint '"$0"'
  Sleep 2500

  Exec "explorer.exe C:\core\infrastructure\ubDistBuild\README-installer.pdf"

  # Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "C:\core\infrastructure\ubDistBuild-uninst.exe"


  # Start Menu
	;createDirectory "$SMPROGRAMS\${COMPANYNAME}"
	;createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\app.exe" "" "$INSTDIR\logo.ico"
 
	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${COMPANYNAME} - ${APPNAME} - ${DESCRIPTION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"C:\core\infrastructure\ubDistBuild-uninst.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"C:\core\infrastructure\ubDistBuild-uninst.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"C:\core\infrastructure\ubDistBuild$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"C:\core\infrastructure\ubDistBuild\_lib\nsis\icon\icon.ico$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "$\"${COMPANYNAME}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "$\"${HELPURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "$\"${UPDATEURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "$\"${ABOUTURL}$\""
	;WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "$\"${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}$\""
	;WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
	;WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}

SectionEnd



function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${APPNAME}?" IDOK next
		Abort
	next:
    Nop
functionEnd
 
section "uninstall"
 
	# Remove Start Menu launcher
	;delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
	# Try to remove the Start Menu folder - this will only happen if it is empty
	;rmDir "$SMPROGRAMS\${COMPANYNAME}"
  
	# Remove files
  RMDir /r "C:\core\infrastructure\ubDistBuild-backup-uninstalled"
  CreateDirectory "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local"
  Rename "C:\core\infrastructure\ubDistBuild\_local\vm.img" "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\vm.img"
  Rename "C:\core\infrastructure\ubDistBuild\_local\vm-live.iso" "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\vm-live.iso"
  Rename "C:\core\infrastructure\ubDistBuild\_local\package_rootfs.tar" "C:\core\infrastructure\ubDistBuild-backup-uninstalled\_local\package_rootfs.tar"
  
  ;RMDir /r "C:\core\infrastructure\ubDistBuild"
  RMDir /r /REBOOTOK "C:\core\infrastructure\ubDistBuild"



  # Rename AND/OR Remove  adjacent installed repositories.
  Rename "C:\core\variant\ubdist_dummy" "C:\core\variant\ubdist_dummy-uninstalled-$0"
  RMDir /r /REBOOTOK "C:\core\variant\ubdist_dummy"
  ;...

  # Rename AND/OR Remove  adjacent installed repositories.
  Rename "C:\core\variant\ubdist_puddleJumper" "C:\core\variant\ubdist_puddleJumper-uninstalled-$0"
  RMDir /r /REBOOTOK "C:\core\variant\ubdist_puddleJumper"
  ;...


 
	# Always delete uninstaller as the last action
	delete "C:\core\infrastructure\ubDistBuild-uninst.exe"
 
	# Try to remove the install directory - this will only happen if it is empty
	;rmDir $INSTDIR
 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
sectionEnd








