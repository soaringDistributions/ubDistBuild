

# CAUTION: DANGER: This script and these commands WILL erase data on your disk!

if ( [[ "$profileScriptLocation" != "" ]] || [[ "$ub_import" == "true" ]] || env | grep -i '^kde\|kde$' > /dev/null 2>&1 || [[ "$XDG_SESSION_DESKTOP" != "" ]] || [[ "$XDG_CURRENT_DESKTOP" != "" ]] )
then
	exit 0
	return 0
fi

#_messagePlain_warn 'WARNING: will ERASE DATA on your disk!'
echo -e -n '\E[1;33m '
echo ' ''WARNING: will ERASE DATA on your disk!'
echo -e -n ' \E[0m'
echo 'NOT for computers with existing dist/OS!'
echo 'Ctrl+c repeatedly to cancel!'

echo 'wait: 15seconds: Ctrl+c repeatedly to cancel NOW!!!'
#local currentIteration
for currentIteration in $(seq 1 15)
do
	sleep 1
done
#_messagePlain_warn 'NOT cancelled!'
echo -e -n '\E[1;33m '
echo ' ''NOT cancelled!'
echo -e -n ' \E[0m'


# NOTICE

#export ssh="" ; wget -qO- https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/install/ubdist.sh | bash

#export ssh="" ; export GH_TOKEN="" ; export owner="" ; export repo="" ; export INPUT_GITHUB_TOKEN="$GH_TOKEN" ; wget -qO- https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/install/ubdist.sh | bash












[[ "$owner" == "" ]] && export owner=soaringDistributions
[[ "$repo" == "" ]] && export repo=ubDistBuild
[[ "$dev" == "" ]] && export dev=/dev/sda
[[ "$rl" == "" ]] && export rl=latest
[[ "$ssh" == "" ]] && export ssh=

! cd && echo 'FAIL: cd' && exit 1

sudo -n apt-get update
sudo -n apt-get install -y wget curl aria2 axel openssl jq git lz4 bc xxd;
sudo -n apt-get install -y gh;

wget https://raw.githubusercontent.com/mirage335-colossus/ubiquitous_bash/master/ubiquitous_bash.sh
! [[ -e ./ubiquitous_bash.sh ]] && echo 'FAIL: missing: ./ubiquitous_bash.sh' && exit 1
chmod 755 ./ubiquitous_bash.sh
mkdir -p ./_local
! ./ubiquitous_bash.sh _true && echo 'FAIL: _true' && exit 1
./ubiquitous_bash.sh _false && echo 'FAIL: _false' && exit 1
./ubiquitous_bash.sh _setupUbiquitous
./ubiquitous_bash.sh _custom_splice_opensslConfig

export profileScriptLocation="/root/ubiquitous_bash.sh"
export profileScriptFolder="/root"
. "/root/ubiquitous_bash.sh" --profile _importShortcuts

#https://github.com/soaringDistributions/ubDistBuild.git
#git@github.com:soaringDistributions/ubDistBuild.git
./ubiquitous_bash.sh _gitBest clone --recursive --depth 1 git@github.com:"$owner"/"$repo".git

! cd "$repo" && echo 'FAIL: cd "$repo"' && exit 1
! [[ -e ./ubiquitous_bash.sh ]] && echo 'FAIL: missing: ./ubiquitous_bash.sh' && exit 1
mkdir -p ./_local
! ./ubiquitous_bash.sh _true && echo 'FAIL: _true' && exit 1
./ubiquitous_bash.sh _false && echo 'FAIL: _false' && exit 1

#export FORCE_AXEL=8
#export FORCE_WGET=true
# DANGER: Do NOT enable DANGERfast_EXPERIMENT unless both necessary and using appropriate specialized/expendable/cloud computers for development purposes only.
#export DANGERfast_EXPERIMENT=true
if [[ "$DANGERfast_EXPERIMENT" == "" ]] || [[ "$DANGERfast_EXPERIMENT" == "false" ]] || [[ "$DANGERfast_EXPERIMENT" == "build" ]]
then
	./ubiquitous_bash.sh _get_vmImg_ubDistBuild "$rl" "" "$dev"
else
	echo
	./ubiquitous_bash.sh _messagePlain_bad 'warn: bad: DANGERfast_EXPERIMENT:  DANGER: Skipping hash!'
	./ubiquitous_bash.sh _messagePlain_warn 'Do NOT use except during development on specialized/expendable/cloud computers! NO PRODUCTION USE!'
	./ubiquitous_bash.sh _messageError DANGER: Skipping hash!
	echo

	[[ "$rl" == "latest" ]] && export rl=""
	./ubiquitous_bash.sh _wget_githubRelease_join-stdout "$owner"/"$repo" "$rl" "package_image.tar.flx" | ./ubiquitous_bash.sh _get_extract_ubDistBuild-tar --extract ./vm.img --to-stdout | sudo -n dd of="$dev" bs=1M status=progress
fi

if [[ "$dev" == "/dev/"* ]]
then
	export ubVirtImageIsDevice=true
	export ubVirtImageOverride="$dev"
fi


mkdir -p ./_local
./ubiquitous_bash.sh _openChRoot

./ubiquitous_bash.sh _chroot mkdir -p /root/.ssh
echo "$ssh" | ./ubiquitous_bash.sh _chroot tee /root/.ssh/authorized_keys

./ubiquitous_bash.sh _chroot sudo -n -u user bash -c 'cd ; mkdir -p /home/user/.ssh'
echo "$ssh" | ./ubiquitous_bash.sh _chroot tee /home/user/.ssh/authorized_keys
./ubiquitous_bash.sh _chroot chown user:user /home/user/.ssh/authorized_keys

./ubiquitous_bash.sh _chroot sudo -n systemctl enable ssh
./ubiquitous_bash.sh _chroot systemctl enable ssh.service

./ubiquitous_bash.sh _closeChRoot

