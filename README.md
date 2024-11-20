<!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q 
#exit # scriptedIllustrator_markup_uk4uPhB663kVcygT0q 
# <html style="size: letter;"> <!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
#!/usr/bin/env bash

# Dependencies.
# May need 'ubiquitous_bash.sh" in "$PATH".
# GNU Octave, Qalculate - usually dependency of 'calculator' scripts
# recode - usually dependency of 'markup documentation' scripts
# wkhtmltopdf - may be necessary for accurate conversion from HTML to PDF

# NOTICE: README !
# 
# 
# 
# NOTICE: README !

# CAUTION: As a user, you should have been provided a virtual machine or cloud services to run this script - 'ubiquitous bash' provides functions to ease the use of either and both. An SELinux, AppArmor, unprivileged ChRoot, or similar context may be acceptable as well. Routinely modifying, sharing, and running code, may otherwise put both users and organizations at possibly unnecessary risk.


# Copyright and related rights only waived via CC0 if all specified conditions are met.
# *) EITHER, a single file directly output from 'scriptedIllustrator' (which is GPLv3 licensed), OR, not otherwise claimed under other any copyright license.
# *) Is a documentation script including this message which also predominantly creates or represents markup (eg. 'scriptedIllustrator.sh', 'scriptedIllustrator.html', 'scriptedIllustrator.mediawiki.txt').
# *) NOT part of a program to compress, embed, and assemble, functions and other code (waiver does NOT apply to 'tinyCompiler_scriptedIllustrator.sh' ).

# To the extent possible, related software (ie. 'tinyCompiler_scriptedIllustrator.sh' from 'scriptedIllustrator') remains otherwise copyrighted (ie. GPLv3 license).
# Specifically, please do not use 'scriptedIllustrator' code to distribute unpublished proprietary means of creating 'current_internal_CompressedFunctions' .
# Specifically, please do not misconstrue this copyright waiver to negate any copyright claimed when such a documentation script is part of another project or another copyright notice is present (ie. 'otherwise claimed').

# 'For the avoidance of doubt, any information that you choose to store within your own copy' ... 'remains yours' ... 'using' ... 'to publish content doesn't change whatever rights you may have to that content.'
# Although this project has no relation to TiddlyWiki, as stated above, vaguely similar copyright principles are expected to apply. - https://tiddlywiki.com/static/License.html

#__README_uk4uPhB663kVcygT0q_README__


_document_collect() {
# NOTICE: COLLECT

# Not necessary. Warnings about 'command not found' to 'stderr' will be ignored by script pipelines.
#! type -p 'recode' > /dev/null 2>&1 && recode() { false; }


currentByte=8

RECODE_markup_html_pre_begin=$(_safeEcho "$markup_html_pre_begin" | recode ascii..html)


export current_lorem_ipsum='Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'


# NOTICE: COLLECT
}



_document_main() {
#a
#b
# NOTICE: DOCUMENT
#__HEADER_uk4uPhB663kVcygT0q_HEADER__
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">
Copyright (C) 2022 Soaring Distributions LLC
See the end of the file for license conditions.
See license.txt for ubDistBuild license conditions.


Builds custom Linux distribution.

Please contact manager mirage335 of Soaring Distributions LLC to relicense 
these build scripts. Default AGPLv3 license is NOT intended to discourage 
build services with custom modifications, ONLY desired to *encourage* 
contacting Soaring Distributions LLC.

Specifically, Soaring Distributions LLC would prefer to see more CI 
services (eg. Github Actions) with long timeouts (>>6hours), and sufficient 
storage/bandwidth (>>100GB), rather than for displacement of such FLOSS 
compatible services by those only suitable for a narrower purpose possibly 
not immediately compatible with BIOS, EFI, LiveCD, LiveUSB, 
hibernation/bup, _userQemu, _userVBox, Cygwin/MSW, mixed and integrated 
GNU/Linux/MSW virtualization, etc (eg. possibly Vagrant Cloud, 
DockerCE/MSW, VPS cloud image builders). Linux LiveCD, LiveUSB, and the 
flexibility of hibernation/bup are especially necessary along with 
Cygwin/MSW to obviate such legacy issues as the inability to use WSL as a 
dependency (eg. due to non-availability of WSL2 for MSW server, MS track 
record, etc), inability to reliably run PowerShell scripts, poor quality of 
MSW scripting and programming syntax, etc. MSW track record of HyperV 
causing VMWare Workstation compatibility issues is also concerning.

Simply put, great flexibility is needed to ensure developers can use 
GNU/Linux with any available virtualization backend to workaround severe 
poor design and obvious conflicts of interest inherent to MSW. This build 
toolchain, as well as the AGPLv3 license, is mostly intended ONLY to 
protect the availability of that flexibility. *Relicensing* for any purpose 
not expected to immediately harm that flexibility, or which offsets any 
such risk, *is easy*.

Please contact manager mirage335 of Soaring Distributions LLC.
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_heading1' 'Built with Llama'
if false; then true; # -->
<!-- # --><h1>Built with Llama</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">Llama 3.1 is licensed under the Llama 3.1 Community License, Copyright © 
Meta Platforms, Inc. All Rights Reserved.

An AI Large Language Model &#39;Llama-augment&#39; may be included with 
this dist/OS, and may be accessible using the function &#39;l&#39; at the 
command line. The license and terms of use are inherited from the 
&#39;Meta&#39; corporation&#39;s llama3_1 license and use policy.
https://www.llama.com/llama3_1/license/
https://www.llama.com/llama3_1/use-policy/

Copies of these license and use policies, to the extent required and/or 
appropriate, are included in appropriate subdirectories of a proper 
recursive download of any git repository used to distribute this project. 


DANGER!

Please beware this &#39;augment&#39; model is intended for embedded use by 
developers, and is NOT intended as-is for end-users (except possibly for 
non-commercial open-source projects), especially not as any built-in help. 
Features may be removed, overfitting to specific answers may be 
deliberately reinforced, and CONVERSATION MAY DEVIATE FROM SAFE DESPITE 
HARMLESS PROMPTS.

If you are in a workplace or public relations setting, you are recommended 
to avoid providing interactive or visible outputs from an &#39;augment&#39; 
model unless you can safely evaluate that the model provides the most 
reasonable safety for your use case.

PLEASE BE AWARE the &#39;Meta&#39; corporation&#39;s use policy DOES NOT 
ALLOW you to "FAIL TO APPROPRIATELY DISCLOSE to end users any known dangers 
of your AI system".

Purpose of this model, above all other purposes, is both:
(1) To supervise and direct decisions and analysis by other AI models (such 
as from vision encoders, but also mathematical reasoning specific LLMs, 
computer activity and security logging LLMs, etc).
(2) To assist and possibly supervise &#39;human-in-the-loop&#39; decision 
making (eg. to sanity check human responses).
This model&#39;s ability to continue conversation with awareness of 
previous context after repeating the rules of the conversation through a 
system prompt, has been enhanced. Consequently, this model&#39;s ability to 
keep a CONVERSATION positive and SAFE may ONLY be ENHANCED BETTER THAN 
OTHER MODELS if REPEATED SYSTEM PROMPTING and LLAMA GUARD are used.
https://ollama.com/library/llama-guard3


DISCLAIMER

All statements and disclaimers apply as written from the files: 
&#39;ubiquitous_bash/ai/ollama/ollama.sh&#39;
&#39;ubiquitous_bash/shortcuts/ai/ollama/ollama.sh&#39;

In particular, any &#39;augment&#39; model provided is with a extensive 
DISCLAIMER regarding ANY AND ALL LIABILITY for any and all use, 
distribution, copying, etc. Anyone using, distributing, copying, etc, any 
&#39;augment&#39; model provided under, through, including, referencing, 
etc, this or any similar disclaimer, whether aware of this disclaimer or 
not, is intended to also be, similarly, to the extent possible, DISCLAIMING 
ANY AND ALL LIABILITY.

Nothing in this text is intended to allow for any legal liability to anyone 
for any and all use, distribution, copying, etc.
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_heading1' 'Legal'
if false; then true; # -->
<!-- # --><h1>Legal</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">Attempts to achieve non-inclusive technology use outcomes by legal 
interpretation through means of reinterpretation by norms, precedent, 
understanding, etc, that did not enjoy widespread respected concensus among 
ethical lawyers by the year 2016, is CONTRARY to the INTENT of both Soaring 
Distributions LLC and of manager mirage335 .

This text is intended to effectively PROHIBIT attempts to reintroduce 
liability through reinterpretation of this text or interpretation within 
any societal context. The intended outcome is to allow all inclusive use of 
this technology, and any legal interpretation based on working backwards 
from a desired outcome would only be respecting the plain meaning, 
reasonableness, or lack of situational absurdity, if the outcome was 
conclusive and consistent with, as stated above, prior legal best practice.
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_heading1' 'Usage'
if false; then true; # -->
<!-- # --><h1>Usage</h1>
<!--
fi
 '_o' '_messagePlain_probe' '_gitBest clone --recursive --depth 1 git@github.com:soaringDistributions/ubDistBuild.git'
if false; then true; # -->
<!-- # --><pre style="-webkit-print-color-adjust: exact;background-color:#848484;margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">
<!-- # --><span style="color:#1818b2;background-color:#848484;"> _gitBest clone --recursive --depth 1 git@github.com:soaringDistributions/ubDistBuild.git</span>
<!-- # --></pre>
<!--
fi
 '_heading1' 'Usage - In-Place - Cloud'
if false; then true; # -->
<!-- # --><h1>Usage - In-Place - Cloud</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">Please use the script at &#39;_lib/install/ubdist.sh&#39; to install to a 
cloud computer from a rescue or live boot.

Some documentation is included with the script, showing how to run the 
script, as well as how to input some common configuration settings, such as 
an authorized SSH login key.

# CAUTION: DANGER: This script and these commands WILL erase data on your 
disk!
You must remove the comment characters for this command to work.

#export ssh="" ; #wget -qO 
https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib
/install/ubdist.sh | bash
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_heading1' 'Usage - In-Place - dist/OS'
if false; then true; # -->
<!-- # --><h1>Usage - In-Place - dist/OS</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">Most of the build process for the ubdist dist/OS can run automatically from 
within a minimal Debian or Ubuntu installation, installing and configuring 
software automatically as needed.

Documented by the relevant kit README at 
&#39;_lib\kit\install\cloud\cloud-init\zRotten\zMinimal\README.md&#39;.

# WARNING: This WILL drastically configure your dist/OS, take at least 40 
minutes to complete, involve multiple automatic reboots, and may omit 
configuring some software (ie. VBoxGuest). The intended use case is cloud 
providers or unusual hardware which strictly must run their own custom 
kernel, etc.

#wget 
https://raw.githubusercontent.com/mirage335/ubiquitous_bash/master/_lib/kit/
install/cloud/cloud-init/zRotten/zMinimal/rotten_install_compressed.sh
#mv rotten_install_compressed.sh rotInsSh
#chmod u+x rotInsSh
##./rotInSSh _custom_kernel
#./rotInsSh _install_and_run

## optional
#./rotInsSh _custom_core_drop
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_heading1' 'Contributions'
if false; then true; # -->
<!-- # --><h1>Contributions</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">
Due to the small scope of this project, contributors with pull requests are 
politely asked, but not necessarily required, to consider unambigiously 
assigning copyright to Soaring Distributions LLC. GPLv3 relicensing is 
expected most likely, though other scenarios are possibile if adequate 
flexibility to workaround MSW is essentially ensured.
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_' '_page'
 '_' '_heading1' 'Design'
 '_' '_page'
 '_' '_heading1' 'Safety'
 '_' '_page'
 '_heading1' 'Reference'
if false; then true; # -->
<!-- # --><h1>Reference</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">https://www.kraxel.org/repos/jenkins/edk2/

https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-20200515.1447.
g317d84abe3.noarch.rpm
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'
 '_' '_page'
 '_heading1' 'Copyright'
if false; then true; # -->
<!-- # --><h1>Copyright</h1>
<!--
fi
_t '
scriptedIllustrator_markup_uk4uPhB663kVcygT0q --><!-- # --><pre style="margin-top: 0px;margin-bottom: 0px;white-space: pre-wrap;">This file is part of ubDistBuild.

ubDistBuild is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ubDistBuild is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with ubDistBuild.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
<!-- # --></pre><!-- scriptedIllustrator_markup_uk4uPhB663kVcygT0q
'



#__FOOTER_uk4uPhB663kVcygT0q_FOOTER__
# NOTICE: DOCUMENT
#y
#z
echo -e '\n\n'
}



# NOTICE: Overrides - new functions .


# NOTICE: Overrides - new functions .


#####Functions. Some may be from 'ubiquitous bash' .
#_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions
current_internal_CompressedFunctions_bytes="12399"
current_internal_CompressedFunctions_cksum="368845939"
current_internal_CompressedFunctions="
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"
! echo "$current_internal_CompressedFunctions" | base64 -d | xz -d > /dev/null && exit 1
source <( echo "$current_internal_CompressedFunctions" | base64 -d | xz -d )
unset current_internal_CompressedFunctions ; unset current_internal_CompressedFunctions_cksum ; unset current_internal_CompressedFunctions_bytes
# https://github.com/mirage335/scriptedIllustrator
#_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions_uk4uPhB663kVcygT0q_compressedFunctions
! _tiny_criticalDep && exit 1

# Special Global Variables
_tiny_set_strings


#####Import ( 'ubiquitous bash' ) .
# WARNING: Do NOT invoke complicated 'ubiquitous bash' functions directly (ie. call "ubiquitous_bash.sh" as a binary from PATH instead) .
# WARNING: If '--call' parameter is changed, 'trap' conflict may occur in some functions (ie. ( '_test_default' ) .
# Keeps "$scriptAbsoluteLocation" pointing to this script file (not 'ubiquitous_bash.sh' ), intentionally.
# Import of 'ubiquitous_bash.sh' intended ONLY to provide most recent 'message' and similar functions.
#_messagePlain_probe() { return; }
! type -p "ubiquitous_bash.sh" > /dev/null 2>&1 && exit 1
[[ "$ubiquitousBashID" != "uk4uPhB663kVcygT0q" ]] && exit 1
current_script_path=$(type -p "ubiquitous_bash.sh")
[[ ! -e "$current_script_path" ]] && exit 1
! ls -l "$current_script_path" 2>/dev/null | grep 'ubiquitous_bash.sh$' > /dev/null 2>&1 && exit 1
export importScriptLocation=$(_getScriptAbsoluteLocation)
export importScriptFolder=$(_getScriptAbsoluteFolder)
. "$current_script_path" --call
unset current_script_path
#_messagePlain_probe "$scriptAbsoluteLocation"
#exit 0



#a
#b
#c
#__HEADER-scriptCode_uk4uPhB663kVcygT0q_HEADER-scriptCode__
#1
#2
#3



#8
#9
#0
#__FOOTER-scriptCode_uk4uPhB663kVcygT0q_FOOTER-scriptCode__
#x
#y
#z

# NOTICE: Overrides ( 'ops.sh' equivalent ).

_default() {
	local current_deleteScriptLocal
	current_deleteScriptLocal="false"
	[[ ! -e "$scriptLocal" ]] && current_deleteScriptLocal="true"
	
	#"$scriptAbsoluteLocation" DOCUMENT > "$scriptAbsoluteLocation".out.txt
	
	_scribble_markdown "$@"
	_scribble_html "$@"
	_scribble_pdf "$@"
	
	local currentScriptBasename
	currentScriptBasename=$(basename "$scriptAbsoluteLocation" | sed 's/\.[^.]*$//')
	"$scriptAbsoluteFolder"/"$currentScriptBasename".html _test
	
	[[ "$current_deleteScriptLocal" == "true" ]] && rmdir "$scriptLocal"
}

# NOTICE: Overrides ( 'ops.sh' equivalent ).


_test() {
	"$scriptAbsoluteLocation" _test_default "$@"
}

if ! [[ "$1" == '_'* ]] && [[ "$1" == 'DOCUMENT' ]]
then
	_document_collect
	_document_main
fi

! [[ "$1" == '_'* ]] && [[ "$1" == 'DOCUMENT' ]] && exit 0
if [[ "$1" == '_'* ]]
then
	"$@"
	exit "$?"
fi



_default "$@"






exit 0
# Append base64 encoded attachment file here.
__ATTACHMENT_uk4uPhB663kVcygT0q_ATTACHMENT__


filename.html # scriptedIllustrator_markup_uk4uPhB663kVcygT0q --> </html>
