# Automated operating system (OS) installation

This is living documentation of a work-in-progress approach to automating the
installation of an OS on a personal computer. There is as of yet no assurance that this
approach is generalized, optimal, successful, or even technically automated.

## Infrastructure

This procedure is currently neither hardware- nor software-agnostic; hence both the
hardware and software being used for development are listed below.

### Hardware

- "Target" computer: (Intel-based) MacBook Air Mid-2013
- "Provisioning" computer: (Intel-based) MacBook Pro 2019 running macOS 15 (Sequoia)
- Ethernet cable
- USB-A to Ethernet adapter
- USB-A thumb drive (32 GB)
- Wireless router with internet access and an Ethernet port

### Software

- "Target" OS: Debian 13 (Trixie)
  - The official Debian 13 64-bit PC disk image can be downloaded from the following
    URL.
    ```
    https://cdimage.debian.org/cdimage/archive/13.4.0/amd64/iso-dvd/debian-13.4.0-amd64-DVD-1.iso
    ```
  - *Debian version 13.4.0 is pinned for reproducibility purposes.*

## Procedure

### Preliminary steps

1. Use the aforementioned URL to download the target OS disk image to the provisioning
   computer.
2. Connect the thumb drive to the provisioning computer.
   - *If a disk image has already been written to the thumb drive, a dialog may appear
     that says "The disk you attached was not readable by this computer.". This is not
     an issue for tools like Balena Etcher (see the next step); select "Ignore".*
3. Write the OS disk image onto the thumb drive.
   - *Use, for example, a tool like [Balena Etcher](https://etcher.balena.io/).*

### Installation steps

1. Connect the target computer to the router via the Ethernet cable and adapter.
2. Insert the bootable thumb drive into the target computer.
3. Press the power button while holding down the `option`/`alt` key to start up the
   target computer and enter the boot manager.
4. Select either of the external drive options labeled "EFI Boot" (represented by yellow
   drive icons).
   - *Both options are functionally identical; choose the left-most option for
     consistency.*
5. When the GRUB menu appears, press `e` to open the GRUB editor.
6. Edit the GRUB script that appears so as to have precisely the following content.
   ```
   setparams 'Graphical install'

       set background_color=black
       linux    /install.amd/vmlinuz auto=true debian-installer/allow_unauthenticated_ssl=true url=https://raw.githubusercontent.com/andrewtbiehl/personal-computing-ecosystem/1c910b96085cf596741f8375ab107f2c7a5a8d76/example-preseed.txt vga=788 --- quiet intel_iommu=off
       initrd   /install.amd/gtk/initrd.gz
   ```
   - *This directs the installer to download and use an unmodified copy of the official
     Debian example preseed file.*
   - ***SECURITY WARNING**: Downloading the preseed file from GitHub.com requires
     bypassing cryptographic server verification. I seriously doubt that this is a safe
     practice and strongly recommend against it.*
   - *This particular preseed file used does **not** fully automate the installation.*
7. Press `F10` to execute the modified entry and begin the installation.
8. Complete the OS installation manually, as prompted by the installer.
