#!/bin/bash

# RUN THIS SCRIPT AS ROOT

# Disk and partition variables
lsblk
printf "\nChoose destination disk for the installation: "
read -r mydisk
mydisk=/dev/${mydisk}
mypartition=${mydisk}1

printf "Give a name to the encrypted partition: "
read -r lukspartition

printf "Type a password for the encrypted partition: "
read -rs lukspass

# Script directory variable
scriptdir=$(pwd)

# Pre-chroot system configuration
# Format destination disk
echo 'type=83' | sfdisk "$mydisk"

# Configure encrypted partition
printf "YES\n%s\n%s" "$lukspass" "$lukspass" | cryptsetup luksFormat --type luks1 "$mypartition"
printf "%s\n" "$lukspass" | cryptsetup luksOpen "$mypartition" "$lukspartition"
mkfs.btrfs /dev/mapper/"$lukspartition"

# System installation
mount /dev/mapper/"$lukspartition" /mnt
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
xbps-install -Sy -R https://repo-default.voidlinux.org/current/musl -r /mnt base-system cryptsetup grub

# Copying grub configuration file
cp "${scriptdir}"/grub /mnt/etc/default/grub

# Entering chroot
cat <<- CHROOT | xchroot /mnt 

  # Initial configuration
  chown root:root /
  chmod 755 /
  printf "changeme\nchangeme" | passwd root

  printf "\nChoose a hostname: "
  read -r myhostname
  echo "\${myhostname}" > /etc/hostname

  # GRUB configuration
  sed -i "s|<UUID>|$(blkid -o value -s UUID "${mypartition}")|g" /etc/default/grub
  

  # LUKS key setup
  dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
  cryptsetup luksAddKey \$mypartition /boot/volume.key
  chmod 000 /boot/volume.key
  chmod -R g-rwx,o-rwx /boot
  echo "install_items+=\" /boot/volume.key /etc/crypttab \"" > /etc/dracut.conf.d/10-crypt.conf

  # Complete system installation

  # Install the bootloader to the disk
  grub-install "${mydisk}"

  # Ensure an initramfs is generated:
  xbps-reconfigure -fa

  # Exit the chroot
  exit
CHROOT

# Umount the filesystems and reboot the system
umount -R /mnt
reboot
