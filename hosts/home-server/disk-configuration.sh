#!/usr/bin/env bash

set -e -x

disks=(/dev/disk/by-id/ata-WDC_WD10EZEX-00BBHA0_WD-WCC6Y2XC5S4R /dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y1FZ1NTR)
swapSize=32
bpoolSize=4
espSize=1
reserveSize=1
MNT=/mnt

mkdir $MNT

i=0
for disk in ${disks[@]}; do
	ls $disk
	blkdiscard -f $disk || true
	parted --script --align=optimal $disk -- \
		   mklabel gpt \
		   mkpart BIOS 1MiB 2MiB \
		   set 1 bios_grub on \
		   set 1 legacy_boot on \
		   mkpart EFI 2MiB $((espSize))GiB \
		   set 2 esp on \
		   mkpart swap  $((espSize))GiB $((espSize + swapSize))GiB \
		   mkpart bpool $((espSize + swapSize))GiB $((espSize + swapSize + bpoolSize))GiB \
		   mkpart rpool $((espSize + swapSize + bpoolSize))GiB -$((reserveSize))GiB
	partprobe $disk
	mkfs.vfat -n EFI $disk-part2
	mkdir -p $MNT/boot/efis/$i
	mount -t vfat -o iocharset=iso8859-1 $disk-part2 $MNt/boot/efis/$i
	i=$((i+1))
done

zpool create \
      -o ashift=12 \
      -o autotrim=on \
	  -o mountpoint=legacy \
      -O acltype=posixacl \
      -O compression=zstd \
      -O dnodesize=auto \
      -O normalization=formD \
      -O relatime=on \
      -O xattr=sa \
      -O mountpoint=/ \
      rpool \
	  mirror \
	  $(for $disk in ${disks[@]}; do  printf '%s ' "${i}-part5"; done)
mkdir $MNT
mount -t zfs rpool $MNT

zfs create -o mountpoint=legacy  rpool/persistent
mkdir $MNT/persistent
mount -t zfs rpool/persistent $MNT/persistent

zpool create \
      -o compatibility=grub2 \
      -o ashift=12 \
	  -o mountpoint=legacy \
      -o autotrim=on \
      -O acltype=posixacl \
      -O compression=lz4 \
      -O devices=off \
      -O normalization=formD \
      -O relatime=on \
      -O xattr=sa \
      -O mountpoint=/boot \
      bpool \
	  mirror \
	  $(for $disk in ${disks[@]}; do  printf '%s ' "${i}-part4"; done)
mkdir $MNT/boot
mount -t zfs bpool $MNT/boot

zfs create -o mountpoint=legacy rpool/empty
zfs snapshot rpool/empty@start
