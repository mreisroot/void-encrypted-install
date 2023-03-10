#!/bin/bash

# RUN THIS SCRIPT AS ROOT!
if [ "$(whoami)" != root ]; then
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

printf "What version of void you're installing? [musl glibc]: "
read -r mylibc

# Script directory variable
scriptdir=$(pwd)

# Void repository variable

# Musl repo
repo=https://repo-default.voidlinux.org/current/musl

# Glibc repo
if [ "$mylibc" == "glibc" ]; then
  repo=https://repo-default.voidlinux.org/current/
fi

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
xbps-install -Sy -R "$repo" -r /mnt base-system cryptsetup grub vim git

# Copying grub configuration file
cp "${scriptdir}"/grub /mnt/etc/default/grub

# Copying hosts file
cp "${scriptdir}"/hosts /mnt/etc/hosts

# Entering chroot
cat <<- CHROOT | xchroot /mnt /bin/bash

  # Initial configuration
  printf "%s\n%s\n" "$rootpass" "$rootpass" | passwd root
  usermod -s /bin/bash root
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
 
  if [ "$mylibc" == "glibc" ]; then
    # glibc locale configuration
    echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
    xbps-reconfigure -f glibc-locales
  fi 

  echo "$myhostname" > /etc/hostname
  sed -i "s/myhostname/$myhostname/g" /etc/hosts

  # LUKS key setup
  dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
  printf "%s\n" "$lukspass" | cryptsetup luksAddKey /dev/disk/by-uuid/$(blkid -o value -s UUID "$mypartition") /crypto_keyfile.bin
  chmod 000 /crypto_keyfile.bin
  chmod -R g-rwx,o-rwx /boot

  # Setup crypttab
  echo "cryptroot UUID=$(blkid -o value -s UUID "$mypartition") /crypto_keyfile.bin luks" >> /etc/crypttab
  echo "install_items+=\" /crypto_keyfile.bin /etc/crypttab \"" > /etc/dracut.conf.d/10-crypt.conf

  # GRUB configuration
  sed -i "s/<UUID>/$(blkid -o value -s UUID "$mypartition")/g" /etc/default/grub

  # Complete system installation

  # Install the bootloader to the disk
  grub-install "$mydisk" --recheck
  grub-mkconfig -o /boot/grub/grub.cfg

  # Ensure an initramfs is generated:
  xbps-reconfigure -fa

  # Exit the chroot
  exit
CHROOT

# Umount the filesystems and reboot the system
umount -R /mnt
reboot
