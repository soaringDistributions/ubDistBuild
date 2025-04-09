
Copyright (C) 2022 Soaring Distributions LLC
See the end of the file for license conditions.
See license.txt for ubDistBuild license conditions.


Builds custom Linux distribution.

Please contact manager mirage335 of Soaring Distributions LLC to relicense these build scripts. Default AGPLv3 license is NOT intended to discourage build services with custom modifications, ONLY desired to *encourage* contacting Soaring Distributions LLC.

Specifically, Soaring Distributions LLC would prefer to see more CI services (eg. Github Actions) with long timeouts (>>6hours), and sufficient storage/bandwidth (>>100GB), rather than for displacement of such FLOSS compatible services by those only suitable for a narrower purpose possibly not immediately compatible with BIOS, EFI, LiveCD, LiveUSB, hibernation/bup, _userQemu, _userVBox, Cygwin/MSW, mixed and integrated GNU/Linux/MSW virtualization, etc (eg. possibly Vagrant Cloud, DockerCE/MSW, VPS cloud image builders). Linux LiveCD, LiveUSB, and the flexibility of hibernation/bup are especially necessary along with Cygwin/MSW to obviate such legacy issues as the inability to use WSL as a dependency (eg. due to non-availability of WSL2 for MSW server, MS track record, etc), inability to reliably run PowerShell scripts, poor quality of MSW scripting and programming syntax, etc. MSW track record of HyperV causing VMWare Workstation compatibility issues is also concerning.

Simply put, great flexibility is needed to ensure developers can use GNU/Linux with any available virtualization backend to workaround severe poor design and obvious conflicts of interest inherent to MSW. This build toolchain, as well as the AGPLv3 license, is mostly intended ONLY to protect the availability of that flexibility. *Relicensing* for any purpose not expected to immediately harm that flexibility, or which offsets any such risk, *is easy*.

Please contact manager mirage335 of Soaring Distributions LLC.

_ Built with Llama _
Llama 3.1 is licensed under the Llama 3.1 Community License, Copyright © Meta Platforms, Inc. All Rights Reserved.

An AI Large Language Model &#39;Llama-augment&#39; may be included with this dist/OS, and may be accessible using the function &#39;l&#39; at the command line. The license and terms of use are inherited from the &#39;Meta&#39; corporation&#39;s llama3_1 license and use policy.
https://www.llama.com/llama3_1/license/
https://www.llama.com/llama3_1/use-policy/

Copies of these license and use policies, to the extent required and/or appropriate, are included in appropriate subdirectories of a proper recursive download of any git repository used to distribute this project. 


DANGER!

Please beware this &#39;augment&#39; model is intended for embedded use by developers, and is NOT intended as-is for end-users (except possibly for non-commercial open-source projects), especially not as any built-in help. Features may be removed, overfitting to specific answers may be deliberately reinforced, and CONVERSATION MAY DEVIATE FROM SAFE DESPITE HARMLESS PROMPTS.

If you are in a workplace or public relations setting, you are recommended to avoid providing interactive or visible outputs from an &#39;augment&#39; model unless you can safely evaluate that the model provides the most reasonable safety for your use case.

PLEASE BE AWARE the &#39;Meta&#39; corporation&#39;s use policy DOES NOT ALLOW you to "FAIL TO APPROPRIATELY DISCLOSE to end users any known dangers of your AI system".

Purpose of this model, above all other purposes, is both:
(1) To supervise and direct decisions and analysis by other AI models (such as from vision encoders, but also mathematical reasoning specific LLMs, computer activity and security logging LLMs, etc).
(2) To assist and possibly supervise &#39;human-in-the-loop&#39; decision making (eg. to sanity check human responses).
This model&#39;s ability to continue conversation with awareness of previous context after repeating the rules of the conversation through a system prompt, has been enhanced. Consequently, this model&#39;s ability to keep a CONVERSATION positive and SAFE may ONLY be ENHANCED BETTER THAN OTHER MODELS if REPEATED SYSTEM PROMPTING and LLAMA GUARD are used.
https://ollama.com/library/llama-guard3


DISCLAIMER

All statements and disclaimers apply as written from the files: &#39;ubiquitous_bash/ai/ollama/ollama.sh&#39;
&#39;ubiquitous_bash/shortcuts/ai/ollama/ollama.sh&#39;

In particular, any &#39;augment&#39; model provided is with a extensive DISCLAIMER regarding ANY AND ALL LIABILITY for any and all use, distribution, copying, etc. Anyone using, distributing, copying, etc, any &#39;augment&#39; model provided under, through, including, referencing, etc, this or any similar disclaimer, whether aware of this disclaimer or not, is intended to also be, similarly, to the extent possible, DISCLAIMING ANY AND ALL LIABILITY.

Nothing in this text is intended to allow for any legal liability to anyone for any and all use, distribution, copying, etc.

_ Legal _
Attempts to achieve non-inclusive technology use outcomes by legal interpretation through means of reinterpretation by norms, precedent, understanding, etc, that did not enjoy widespread respected concensus among ethical lawyers by the year 2016, is CONTRARY to the INTENT of both Soaring Distributions LLC and of manager mirage335 .

This text is intended to effectively PROHIBIT attempts to reintroduce liability through reinterpretation of this text or interpretation within any societal context. The intended outcome is to allow all inclusive use of this technology, and any legal interpretation based on working backwards from a desired outcome would only be respecting the plain meaning, reasonableness, or lack of situational absurdity, if the outcome was conclusive and consistent with, as stated above, prior legal best practice.

_ Usage _
[0;37;100m[0;34m _gitBest clone --recursive --depth 1 git@github.com:soaringDistributions/ubDistBuild.git [0m[0m

_ Usage - In-Place - Cloud _
Please use the script at &#39;_lib/install/ubdist.sh&#39; to install to a cloud computer from a rescue or live boot.

Some documentation is included with the script, showing how to run the script, as well as how to input some common configuration settings, such as an authorized SSH login key.

# CAUTION: DANGER: This script and these commands WILL erase data on your disk!
You must remove the comment characters for this command to work.

#export ssh="" ; #wget -qO https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/install/ubdist.sh | bash

_ Usage - In-Place - dist/OS _
Most of the build process for the ubdist dist/OS can run automatically from within a minimal Debian or Ubuntu installation, installing and configuring software automatically as needed.

Documented by the relevant kit README at &#39;_lib\kit\install\cloud\cloud-init\zRotten\zMinimal\README.md&#39;.

# WARNING: This WILL drastically configure your dist/OS, take at least 40 minutes to complete, involve multiple automatic reboots, and may omit configuring some software (ie. VBoxGuest). The intended use case is cloud providers or unusual hardware which strictly must run their own custom kernel, etc.

#wget https://raw.githubusercontent.com/mirage335/ubiquitous_bash/master/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install_compressed.sh
#mv rotten_install_compressed.sh rotInsSh
#chmod u+x rotInsSh
##./rotInSSh _custom_kernel
#./rotInsSh _install_and_run

## optional
#./rotInsSh _custom_core_drop

_ Contributions _

Due to the small scope of this project, contributors with pull requests are politely asked, but not necessarily required, to consider unambigiously assigning copyright to Soaring Distributions LLC. GPLv3 relicensing is expected most likely, though other scenarios are possibile if adequate flexibility to workaround MSW is essentially ensured.

_ Reference _
https://www.kraxel.org/repos/jenkins/edk2/

https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-20200515.1447.g317d84abe3.noarch.rpm

_ Copyright _
This file is part of ubDistBuild.

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



