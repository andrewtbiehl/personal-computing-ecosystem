# Automated operating system (OS) installation

This is living documentation of a work-in-progress approach to automating the
installation of an OS on a personal computer. There is as of yet no assurance that this
approach is generalized, optimal, successful, or even technically automated.

## Infrastructure

This procedure is currently neither hardware- nor software-agnostic; hence both the
hardware and software being used for development are listed below.

### Hardware

- One "target" computer and one "provisioning" computer
  - (Intel-based) MacBook Air (11-inch, Early 2015)
  - (Intel-based) MacBook Air (11-inch, Mid 2013)
- Two (2) USB-A to Ethernet adapters
  - *It is possible that some adapter-to-computer/OS pairings are incompatible; some
    "mixing and matching" may prove necessary.*
- Ethernet cable
- USB-A thumb drive (32 GB)
- Wireless router with internet access and an Ethernet port

### Software

- "Target" OS: Debian 13 (Trixie). The official Debian 13 64-bit PC disk image can be
  downloaded from the following URL.
  ```
  https://cdimage.debian.org/cdimage/archive/13.5.0/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso
  ```
  We hereafter refer to this URL via the indeterminate `<os-disk-image-url>`.
  - *Debian version 13.5.0 is pinned for reproducibility purposes.*

## Procedure

### Preliminary steps

1. If required or inclined to do so, perform the following steps to set up the
   provisioning computer.
   1. Reset the provisioning computer to factory settings and install the latest version
      of MacOS that it supports.
   2. Install Xcode Command Line Tools via the following command.
      ```sh
      xcode-select --install
      ```
2. Clone this repository to the provisioning computer.
3. Download the target OS disk image, located at the url `<os-disk-image-url>`, to the
   provisioning computer.
4. Connect the thumb drive to the provisioning computer and write the OS disk image onto
   the thumb drive.
   - *Use, for example, a tool like [Balena Etcher](https://etcher.balena.io/).*
   - *If a disk image has already been written to the thumb drive, a dialog may appear
     that says "The disk you attached was not readable by this computer.". This is not
     an issue for tools like Balena Etcher; select "Ignore".*
   - *Balena Etcher may temporarily require full disk access to operate successfully.*
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
   2. Connect one compatible Ethernet adapter to the computer.
   3. Open a new shell session to start up a DHCP server bound to the Ethernet adapter
      interface.
      1. Run the following command to determine the name assigned to the adapter
         interface.
         ```sh
         networksetup -listallhardwareports
         ```
         We hereafter refer to this name via the indeterminate `<interface-name>`.
      2. Run the following command to assign the static IP address `192.168.1.1` to the
         adapter interface.
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
   4. Open a new shell session and start up an HTTP server that serves the contents of
      this repository via the following command.
      ```sh
      python3 -m http.server 8080
      ```
      - *Remember to shut down the HTTP server after completing these steps.*
2. Perform the following steps on the (initially powered off) target computer.
   1. Connect the target computer to the provisioning computer via the Ethernet cable
      and adapters.
   2. Insert the bootable thumb drive into the computer.
   3. Press the power button while holding down the `option`/`alt` key to start up the
      computer and enter the boot manager.
   4. Select any of the external drive options labeled "EFI Boot" (represented by yellow
      drive icons).
      - *All options are functionally identical; if there is more than one, choose the
        left-most option for consistency.*
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
2. Connect the computer to the router via the Ethernet cable and compatible adapter.
3. Clone this repository to the computer.
4. Set up software repositories for the APT package manager via the following command.
   ```sh
   su --login root --command="
     cp /usr/share/doc/apt/examples/debian.sources /etc/apt/sources.list.d/debian.sources
   "
   ```
   - *This particular step does not require an internet connection.*
5. Set up wireless networking capability.
   1. Install all necessary packages via the following command.
      ```sh
      su --login root --command="
        apt-get update \
          && apt-get install --assume-yes linux-image-amd64 linux-headers-amd64 broadcom-sta-dkms
      "
      ```
   2. Log out, restart the computer, and log in.
6. Detach the Ethernet cable and adapter from the computer.
7. Download the target OS disk image to the computer via the following command.
   ```sh
   wget <os-disk-image-url>
   ```
8. Connect the thumb drive to the computer and write the OS disk image onto the thumb
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
