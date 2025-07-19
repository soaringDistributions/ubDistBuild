
---

BEGIN directory specific "ubDistBuild" AGENTS.md , other input may regard other hierarchical directories.

The ubDistBuild project is a 'fork' derivative of 'ubiquitous_bash' using the shell script functions, compile, etc, of 'ubiquitous_bash' as a library. To understand how this project works, please also read the ./_lib/ubiquitous_bash/AGENTS.md file .


# Notable "ubDistBuild" Subdirectories and Files

## _prog

Most bash shellcode used to build, download, etc, ubdist/OS . Compiled into 'ubiquitous_bash.sh' .

## _prog-ops

Some code included as a runtime import into the shell script, rather than compiled in.

## _lib/_build-staging-ops

Maintenance code added to workaround enivionment changes, needed features, etc, but usually not yet having sufficient track record to disperse appropriately throughout the codebase.

## _lib/nsis/ubDistBuild.nsi

The build for the MSWindows installer used to download ubdist/OS, install and configure WSL2, etc. Because the installer build runs under UNIX/Linus, and because the installer itself early installs a 'ubcp' Cygwin environment, 'ubiquitous_bash' bash shell script functions are called for both the build process and to carry out some of the installation steps.



END directory specific "ubDistBuild" AGENTS.md , other input may regard other hierarchical directories.

---
