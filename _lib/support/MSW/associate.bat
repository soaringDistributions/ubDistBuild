@echo off

REM https://www.reddit.com/r/bashonubuntuonwindows/comments/9ax19o/how_to_set_wsl_program_as_default_program_for/

REM ftype geda.schematic=wslg.exe ~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap gschem $(wslpath "%1")



echo BATCH: Setting file type association...

assoc %2=%1

:: Use double percentage to escape %1
ftype %1=wslg.exe ~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh _wrap %3 $(wslpath "%%1")

echo BATCH: Done.
exit /b




