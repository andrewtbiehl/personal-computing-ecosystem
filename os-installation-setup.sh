#!/bin/sh

# Attempt to correctly identify the internal drive block device name.
INTERNAL_DRIVE_DEVICE_NAME=$(lsblk --paths --nodeps --noheadings \
    --output NAME,TYPE,TRAN | awk '$2 == "disk" && $3 != "usb" {print $1}')

# Wipe the identified drive of all filesystems and partition tables, create and
# format a new EFI System Partition on the drive, download the netboot kernel
# and initial ramdisk to the partition, and install the systemd-boot bootloader
# on the partition and register it with NVRAM.
wipefs --all $INTERNAL_DRIVE_DEVICE_NAME \
  && sgdisk --zap-all $INTERNAL_DRIVE_DEVICE_NAME \
  && sgdisk --new=1:0:+512M --typecode=1:EF00 --change-name=1:EFI_PARTITION \
    $INTERNAL_DRIVE_DEVICE_NAME \
  && udevadm settle \
  && mkfs.vfat /dev/disk/by-partlabel/EFI_PARTITION \
  && mount --mkdir /dev/disk/by-partlabel/EFI_PARTITION /mnt/efi \
  && curl --remote-name-all --output-dir /mnt/efi \
    http://192.168.1.1:8000/linux \
    http://192.168.1.1:8000/initrd.gz \
  && bootctl --esp-path=/mnt/efi install

# Create the default boot entry configuration file.
cat << 'EOF' > /mnt/efi/loader/entries/default.conf
linux /linux
initrd /initrd.gz
options auto=true priority=critical --- intel_iommu=off
EOF

# Restart the computer.
reboot
