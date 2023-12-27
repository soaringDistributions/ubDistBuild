
#export ssh="" ; wget -qO- https://bit.ly/ubdist | bash

#export ssh="" ; wget -qO- https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/install/ubdist.sh | bash

#export ssh="" ; export GH_TOKEN="" ; export owner="" ; export repo="" ; wget -qO- https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/install/ubdist.sh | bash


[[ "$owner" == "" ]] && export owner=soaringDistributions
[[ "$repo" == "" ]] && export repo=ubDistBuild
[[ "$dev" == "" ]] && export dev=/dev/sda
[[ "$rl" == "" ]] && export rl=latest
[[ "$ssh" == "" ]] && export ssh=

cd

sudo -n apt-get update
sudo -n apt-get install -y wget curl aria2 axel openssl jq git lz4 bc xxd;
sudo -n apt-get install -y gh;

wget https://raw.githubusercontent.com/mirage335-colossus/ubiquitous_bash/master/ubiquitous_bash.sh
chmod 755 ./ubiquitous_bash.sh
./ubiquitous_bash.sh _setupUbiquitous
./ubiquitous_bash.sh _custom_splice_opensslConfig

export profileScriptLocation="/root/ubiquitous_bash.sh"
export profileScriptFolder="/root"
. "/root/ubiquitous_bash.sh" --profile _importShortcuts

#https://github.com/soaringDistributions/ubDistBuild.git
#git@github.com:soaringDistributions/ubDistBuild.git
./ubiquitous_bash.sh _gitBest clone --recursive --depth 1 git@github.com:"$owner"/"$repo".git

cd "$repo"

#export FORCE_AXEL=8
#export FORCE_WGET=true
./ubiquitous_bash.sh _get_vmImg_ubDistBuild "$rl" "" "$dev"

if [[ "$dev" == "/dev/"* ]]
then
	export ubVirtImageIsDevice=true
	export ubVirtImageOverride="$dev"
fi


./ubiquitous_bash.sh _openChRoot

./_chroot mkdir -p /root/.ssh
echo "$ssh" | ./_chroot tee /root/.ssh/authorized_keys

./_chroot sudo -n -u user bash -c 'cd ; mkdir -p /home/user/.ssh'
echo "$ssh" | ./_chroot tee /home/user/.ssh/authorized_keys
./_chroot chown user:user /home/user/.ssh/authorized_keys

./_chroot sudo -n systemctl enable ssh
./_chroot systemctl enable ssh.service

./ubiquitous_bash.sh _closeChRoot

