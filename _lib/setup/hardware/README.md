
```

# WARNING: May be untested.

# Three scripts. May quickly install useful software and configuration to desktop with NVIDIA hardware and other hardware.
# User password will be changed to random.
# https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_compatibility
#wget https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/setup/nvidia/_get_nvidia.sh
#wget https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/setup/hardware/_get_hardware.sh

wget https://bit.ly/getNvSh
chmod u+x getNvSh
./getNvSh _install

wget https://raw.githubusercontent.com/soaringDistributions/ubDistBuild/main/_lib/setup/hardware/_get_hardware.sh
chmod u+x _get_hardware.sh
./_get_hardware.sh _install

wget https://bit.ly/rotInsSh
chmod u+x rotInsSh
./rotInsSh _custom_kernel
./rotInsSh _install_and_run

# optional
./rotInsSh _custom_core_drop

```

