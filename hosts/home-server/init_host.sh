#!/usr/bin/env bash

set -e -x

if !command git; then
	echo "Please run 'nix-shell -p gitMinimal' and rerun this script"
	exit 1
fi

reformat=
disks=(
	/dev/disk/by-id/ata-WDC_WD10EZEX-00BBHA0_WD-WCC6Y2XC5S4R
	/dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y1FZ1NTR
)
biosEnd=+2MiB
espEnd=+1G
swapEnd=+16G
bootEnd=+5G
tankEnd=-1G
biosPart=1
espPart=2
swapPart=3
bootPart=4
tankPart=5
mountpoints=(/$ /nix/var /nix/store /home /var /data)
MNT=/mnt

for disk in ${disks[@]}; do
	ls $disk
	for partition in $disk*; do
		umount $partition || true
	done
done

swap_devs=$(swapon --show=NAME --noheadings)
for swap_dev in $swap_devs; do
	swapoff $swap_dev
done

zpools=$(zpool list -Ho name)
for zpool in $zpools; do
	zpool destroy -f $zpool
done

for disk in ${disks[@]}; do
	sector_size=$(hdparm -I $disk | sed --quiet 's/^\s*Physical Sector size: *\(.*\) bytes$/\1/p')
	wipefs --all --force $disk
	sgdisk \
		--zap-all \
		--mbrtogpt \
		--clear \
		--set-alignment=$sector_size \
		--new=$biosPart:1M:$biosEnd --typecode=$biosPart:EF02 --change-name=$biosPart:bios --attributes=$biosPart:set:2 \
		--new=$espPart:0:$espEnd    --typecode=$espPart:EF00  --change-name=$espPart:esp   \
		--new=$swapPart:0:$swapEnd  --typecode=$swapPart:8200 --change-name=$swapPart:swap \
		--new=$bootPart:0:$bootEnd  --typecode=$bootPart:BE00 --change-name=$bootPart:boot \
		--new=$tankPart:0:$tankEnd  --typecode=$tankPart:FD00 --change-name=$tankPart:tank \
		$disk
	partprobe $disk
	udevadm settle
	mkfs.vfat -n EFI $disk-part$espPart
	mkswap $disk-part$swapPart
	swapon $disk-part$swapPart
	# zpool labelclear -f $disk
done

zpool create \
      -o ashift=12 \
      -o autotrim=on \
      -O mountpoint=legacy \
      -O acltype=posixacl \
      -O canmount=off \
      -O compression=on \
      -O dnodesize=auto \
      -O normalization=formD \
      -O relatime=on \
      -O xattr=sa \
      -R $MNT \
      -f \
      tank \
      mirror \
      $(for disk in ${disks[@]}; do echo $disk-part$tankPart; done)

rm -rf $MNT
for mountpoint in ${mountpoints[@]}; do
	name=$(echo $mountpoint | sed --expr 's#/##g' --expr 's#\$#root#g')
	zfs create -o mountpoint=legacy -o canmount=on tank/$name
	mkdir -p $MNT$mountpoint
done

zfs set relatime=off atime=off tank/nixvar
zfs set relatime=off atime=off tank/nixstore

zfs create -o mountpoint=legacy tank/empty
zfs snapshot tank/empty@start

zpool create \
      -o compatibility=grub2 \
      -o ashift=12 \
      -o autotrim=on \
      -O acltype=posixacl \
      -O canmount=off \
      -O compression=on \
      -O devices=off \
      -O normalization=formD \
      -O relatime=on \
      -O xattr=sa \
      -O mountpoint=legacy \
	  -R $MNT/boot \
	  -f \
      bpool \
	  mirror \
	  $(for disk in ${disks[@]}; do echo $disk-part$bootPart; done)

zfs create -o mountpoint=legacy -o canmount=on bpool/boot

for mountpoint in ${mountpoints[@]}; do
	name=$(echo $mountpoint | sed --expr 's#/##g' --expr 's#\$#root#g')
	mount -t zfs tank/$name $MNT$mountpoint
done

mkdir $MNT/boot
mount -t zfs bpool/boot $MNT/boot

i=0
for disk in ${disks[@]}; do
	mkdir -p $MNT/boot/efis/$i
	mount -t vfat -o iocharset=iso8859-1 $disk-part$espPart $MNT/boot/efis/$i
	i=$((i+1))
done

rm -f ~/.config/nix/nix.conf
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

nixos-install --flake .#home-server --no-root-password
umount -R /mnt
zpool export -a
# nixos-rebuild test --flake .#home-server


# https://github.com/NixOS/nixpkgs/issues/201677
