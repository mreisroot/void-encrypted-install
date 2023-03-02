# Encrypted installation script for Void Linux

The [install.sh](./install.sh) script automatically installs Void Linux with Full Disk Encryption using LUKS on MBR BIOS systems.

The only interaction needed happens on the beginning of the script: to choose the destination disk for the installation, type a password for the encrypted partition (don't worry, the script won't echo the passwords you're typing), type a password for the root user, set a hostname for the installed system and choose the standard C library.

Since this is an installation script, I won't provide a testing environment with a Vagrantfile, like I did in the suckless desktop projects I launched, as vagrant boxes are pre-installed systems, so the script won't work in this case.

## Preparation

[Get an ISO of Void Linux musl](https://voidlinux.org/download/)

Burn this ISO to a flash drive or create a VM with this ISO.

## How to use this project

When the system from the ISO you downloaded boots, do the following:

1. Login into the live system:

```sh
login: root
password: voidlinux
```

By default, the root user is set to use /bin/sh as the shell. If you want to use bash, simply type and run:

`bash`

2. Install git

Make sure the system has git installed:

```sh
xbps-install -Su --yes xbps
xbps-install -Syy --yes git
```

3. Clone this project

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
