# Encrypted installation script for Void Linux

The [install.sh](./install.sh) script automatically installs Void Linux with Full Disk Encryption using LUKS.

The only interaction needed is to choose the destination disk and to give a name to the encrypted partition.

I tailored this script to make a musl installation of Void Linux, because I'm experimenting with the musl library. But, you can change this script to fit a glibc installation.

This script automates the steps from this [Void Linux Handbook article](https://docs.voidlinux.org/installation/guides/fde.html) and make adaptations on the disk setup part by using some steps from [this article from unixsheikh.com](https://www.unixsheikh.com/tutorials/real-full-disk-encryption-using-grub-on-artix-linux-for-bios-and-uefi.html).

Since this is an installation script, I won't provide a testing environment with a Vagrantfile, as vagrant boxes are pre-installed systems, so the script won't work in this case.

## Preparation

[Get an ISO of Void Linux musl](https://voidlinux.org/download/)

Burn this ISO to a flash drive or create a VM with this ISO.

## How to use this project

When the system from the ISO you downloaded boots, do the following:

1. Install git

Make sure the system has git installed:

```sh
sudo xbps-install -Su --yes xbps
sudo xbps-install -S --yes git
```

2. Clone this project

`git clone https://gitlab.com/mreisroot/void-encrypted-setup`

or 

`git clone https://github.com/mreisroot/void-encrypted-setup`

3. cd into the script directory:

`cd void-encrypted-setup`

4. Give the script permission to execute:

`chmod +x install.sh`

5. Run the script

`./install.sh`

## License

Licensed under the [GNU General Public License v2.0](./LICENSE)
