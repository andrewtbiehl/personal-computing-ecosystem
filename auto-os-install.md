# Automated operating system (OS) installation

This is living documentation of a work-in-progress approach to automating the
installation of an OS on a personal computer. There is as of yet no assurance that this
approach is generalized, optimal, successful, or even technically automated.

## Infrastructure

This procedure is currently neither hardware- nor software-agnostic; hence both the
hardware and software being used for development are listed below.

### Hardware

- "Target" computer: (Intel-based) MacBook Air (11-inch, Mid 2013)
- "Provisioning" computer: (Intel-based) MacBook Air (11-inch, Early 2015)
- Ethernet cable
- "Target" USB-A to Ethernet adapter, compatible with the target computer
- "Provisioning" USB-A to Ethernet adapter, compatible with the provisioning computer
- USB-A thumb drive (32 GB)
- Wireless router with internet access and an Ethernet port

### Software

- "Target" OS: Debian 13 (Trixie). The official Debian 13 64-bit PC disk image can be
  downloaded from the following URL.
  ```
  https://cdimage.debian.org/cdimage/archive/13.5.0/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso
  ```
  - *Debian version 13.5.0 is pinned for reproducibility purposes.*

## Procedure

### Preliminary steps

1. If required or inclined to do so, perform the following steps to set up the
   provisioning computer.
   1. Reset the provisioning computer to factory settings and install MacOS 12
      (Monterey).
   2. Install Xcode Command Line Tools (via the command `xcode-select --install`).
2. Clone this repository to the provisioning computer.
3. Use the aforementioned URL to download the target OS disk image to the provisioning
   computer.
4. Connect the thumb drive to the provisioning computer and write the OS disk image onto
   the thumb drive.
   - *Use, for example, a tool like [Balena Etcher](https://etcher.balena.io/).*
   - *If a disk image has already been written to the thumb drive, a dialog may appear
     that says "The disk you attached was not readable by this computer.". This is not
     an issue for tools like Balena Etcher; select "Ignore".*
5. Install [Dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) to the desktop
   directory of the provisioning computer via the following command.
   ```sh
   git -C ~/Desktop clone http://thekelleys.org.uk/git/dnsmasq.git \
     && git -C ~/Desktop/dnsmasq checkout v2.91 \
     && make -C ~/Desktop/dnsmasq
   ```
   - *Dnsmasq version 2.91 is pinned for reproducibility purposes.*

### Installation steps

1. Perform the following steps on the provisioning computer.
   1. Ensure the computer is disconnected from the internet.
   2. Connect the provisioning adapter to the computer.
   3. Open a new shell session to start up a DHCP server bound to the provisioning
      adapter interface.
      1. Run the following command to determine the name assigned to the provisioning
         adapter interface.
         ```sh
         networksetup -listallhardwareports
         ```
         We hereafter refer to this name via the indeterminate `<interface-name>`.
      2. Run the following command to assign the static IP address `192.168.1.1` to the
         provisioning adapter interface.
         ```sh
         sudo ifconfig <interface-name> 192.168.1.1 netmask 255.255.255.0 up
         ```
      3. Start up the DHCP server via the following command.
         ```sh
         sudo ~/Desktop/dnsmasq/src/dnsmasq \
           --interface=<interface-name> \
           --dhcp-boot=http://192.168.1.1:8080/preseed.txt \
           --dhcp-range=192.168.1.2,192.168.1.2 \
           --dhcp-leasefile=/tmp/dnsmasq.leases \
           --no-daemon
         ```
      - *After completing these steps, remember to shut down the DHCP server and then
        reset the adapter interface configuration via the following command.*
        ```sh
        sudo rm /tmp/dnsmasq.leases \
          && sudo ifconfig <interface-name> delete 192.168.1.1
        ```
   4. Open a new shell session to start up a local HTTP server on port `8080` of the
      computer, serving the contents of this repository.
      - *This can be achieved by, for example, running the command
        `python3 -m http.server 8080`. This starts an HTTP server that makes the preseed
        file accessible on the local network at the URL
        `http://192.168.1.1:8080/preseed.txt`.*
      - *Remember to shut down the HTTP server after completing these steps.*
2. Perform the following steps on the (initially powered off) target computer.
   1. Connect the target computer to the provisioning computer via the Ethernet cable
      and adapters.
   2. Insert the bootable thumb drive into the computer.
   3. Press the power button while holding down the `option`/`alt` key to start up the
      computer and enter the boot manager.
   4. Select either of the external drive options labeled "EFI Boot" (represented by
      yellow drive icons).
      - *Both options are functionally identical; choose the left-most option for
        consistency.*
   5. When the GRUB menu appears, press `e` to open the GRUB editor.
   6. Edit the GRUB script that appears so as to have precisely the following content.
      ```
      linux /install.amd/vmlinuz auto=true priority=critical --- intel_iommu=off
      initrd /install.amd/initrd.gz
      ```
   7. Press `F10` to execute the modified entry and begin the installation.
      - *Once the installation has completed, the computer will power off.*

### Postliminary steps

In anticipation of the transition to a Linux-native procedure, perform the following
steps on the target computer.

1. Start up the computer and log in.
2. Set up software repositories for the APT package manager via the following command.
   ```sh
   su --login root --command="
     cp /usr/share/doc/apt/examples/debian.sources /etc/apt/sources.list.d/debian.sources
   "
   ```
3. Set up wireless connectivity.
   1. Connect the computer to the router via the Ethernet cable.
   2. Install all necessary packages via the following command.
      ```sh
      su --login root --command="
        apt-get update \
          && apt-get install --assume-yes linux-image-amd64 linux-headers-amd64 broadcom-sta-dkms
      "
      ```
   3. Detach the Ethernet cable, log out, restart the computer, and log in.
4. Clone this repository to the computer.
5. Download the target OS disk image to the computer via the following command.
   ```sh
   wget https://cdimage.debian.org/cdimage/archive/13.5.0/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso
   ```
6. Connect the thumb drive to the computer and write the OS disk image onto the thumb
   drive.
   1. Open the GNOME Disks application.
   2. Connect the thumb drive and select it inside GNOME Disks.
   3. Click "Drive Options" ("&#8942;" icon) and then click "Restore Disk Image...".
   4. Select the disk image file as the "Image to Restore", click "Start Restoring...",
      and click "Restore".
   5. Click "Power off this disk" ("&#9211;" icon).
   6. Remove the thumb drive.

## Notes

- ***SECURITY WARNING**: Both the root and new user passwords have been hard coded as
  'password'. This is a weak password choice. Moreover, it is obviously not a good
  practice to use the same password as both the root and new user password. Both
  practices should be avoided in any production setting.*
