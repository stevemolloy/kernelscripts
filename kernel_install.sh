#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ ! -f .config ]; then
	echo No .config file. Exiting.
	exit 1
fi

ext=$(grep CONFIG_LOCALVERSION= .config | cut -d \" -f 2)
echo Kernel extension: $ext

if [ -f /boot/vmlinuz-linux$ext ]; then
	echo Kernel already exists! Exiting.
	exit 1
fi


echo make modules_install
make modules_install

echo Copying kernel to /boot
cp -v arch/x86_64/boot/bzImage /boot/vmlinuz-linux$ext

echo Making mkinitcpio preset file
/bin/cat <<EOM > /etc/mkinitcpio.d/linux$ext.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux$ext"

PRESETS=('default' 'fallback')

default_image="/boot/initramfs-linux$ext.img"

fallback_image="/boot/initramfs-linux$ext-fallback.img"
fallback_options="-S autodetect"
EOM

echo mkinitcpio
mkinitcpio -p linux$ext

echo Adding the new kernel to GRUB
grub-mkconfig -o /boot/grub/grub.cfg

