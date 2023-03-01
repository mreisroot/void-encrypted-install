#!/bin/bash

# RUN THIS SCRIPT AS ROOT!
if [ $(whoami) != root ]; then
  echo "RUN THIS SCRIPT AS ROOT!"
  exit 1
fi

# User interaction and some variables
clear
lsblk
printf "\nChoose destination disk for the installation: "
read -r mydisk
mydisk=/dev/${mydisk}
mypartition=${mydisk}1

printf "Type a password for the encrypted partition: "
read -rs lukspass

printf "\nType a new password for the root user: "
read -rs rootpass

printf "\nType a new hostname for the installed system: "
read -r myhostname

# Script directory variable
scriptdir=$(pwd)

# Pre-chroot system configuration

# Format destination disk
echo 'type=83' | sfdisk "$mydisk"

# Configure encrypted partition
printf "%s\n%s\n" "$lukspass" "$lukspass" | cryptsetup luksFormat -q --type luks1 "$mypartition" 
printf "%s\n" "$lukspass" | cryptsetup open "$mypartition" cryptroot
mkfs.btrfs /dev/mapper/cryptroot

# Mount filesystems
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/dev /mnt/proc /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys /mnt/sys

# System installation
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
xbps-install -Sy -R https://repo-default.voidlinux.org/current/musl -r /mnt base-system cryptsetup grub vim

# Copying grub configuration file
cp "${scriptdir}"/grub /mnt/etc/default/grub

# Entering chroot
cat <<- CHROOT | chroot /mnt /bin/bash

  # Initial configuration
  printf "%s\n%s\n" "$rootpass" "$rootpass" | passwd root
  usermod -s /bin/bash root
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  echo "$myhostname" > /etc/hostname

  # LUKS key setup
  dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
  cryptsetup luksAddKey /dev/disk/by-uuid/$(blkid -o value -s UUID "${mypartition}") /crypto_keyfile.bin
  chmod 000 /crypto_keyfile.bin
  chmod -R g-rwx,o-rwx /boot

  # Setup crypttab
  echo "cryptroot UUID=$(blkid -o value -s UUID "${mypartition}") /crypto_keyfile.bin luks" >> /etc/crypttab
  echo "install_items+=\" /crypto_keyfile.bin /etc/crypttab \"" > /etc/dracut.conf.d/10-crypt.conf

  # GRUB configuration
  sed -i "s|<UUID>|$(blkid -o value -s UUID "${mypartition}")|g" /etc/default/grub
  
  # Complete system installation

  # Install the bootloader to the disk
  grub-install "${mydisk}" --recheck
  grub-mkconfig -o /boot/grub/grub.cfg

  # Ensure an initramfs is generated:
  xbps-reconfigure -fa

  # Exit the chroot
  exit
CHROOT

# Umount the filesystems and reboot the system
umount -R /mnt
reboot
