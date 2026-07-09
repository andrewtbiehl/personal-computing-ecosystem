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
- (Optional) Additional computer for testing local network access to provisioning
  computer
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
4. Clone this repository to the provisioning computer.
5. Determine the local IP address of the provisioning computer and a port on which to
   serve a local HTTP server. We hereafter refer to this address and port via the
   indeterminates `<provisioning.ip>` and `<port>`, respectively.
   - *Use, for example, port 8080.*

### Installation steps

1. Start up a local HTTP server on port `<port>` of the provisioning computer, serving
   the contents of this repository.
   - *This can be achieved by, for example, running the command
     `python -m http.server <port>`. This starts an HTTP server that makes the preseed
     file accessible on the local network at the URL
     `http://<provisioning.ip>:<port>/preseed.txt`.*
   - *You may need to disable the secondary computer's firewall temporarily.*
   - *Once the HTTP server is running, consider testing the preseed file URL from any
     other computer on the local network.*
   - *Remember to shut down the HTTP server and possibly reenable the firewall after
     completing these steps.*
2. Perform the following steps on the target computer.
   1. Connect the computer to the router via the Ethernet cable and adapter.
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
      linux /install.amd/vmlinuz auto=true priority=critical url=http://<provisioning.ip>:<port>/preseed.txt --- intel_iommu=off
      initrd /install.amd/initrd.gz
      ```
      - *This directs the installer to download and use a basic Debian preseed file.*
      - *This particular preseed file does **not** fully automate the installation.*
   7. Press `F10` to execute the modified entry and begin the installation.
   8. Complete the OS installation, as prompted by the installer, with the following
      inputs.
      1. Set the root password to `password`.
         - ***SECURITY WARNING**: This is a very weak password and should not be used in
           a production setting.*
         - *You will need to type the password in twice to verify correctness.*
      2. Create a new user account with a 'full name' of `Andrew` and a 'username' of
         `andrew`.
      3. Set the aforementioned new user's password to `password`.
         - ***SECURITY WARNING**: It is obviously not a good practice to use the same
           password as both the root and new user password. This practice should be
           avoided in any production setting.*
         - *You will need to type the password in twice to verify correctness.*
      4. Choose the 'Guided - use entire disk' partitioning method.
      5. Select the internal 'Apple SSD' as the disk to partition.
      6. Select 'Finish partitioning and write changes to disk'.
      7. Answer 'Yes' to the question 'Write changes to disks?'.
      8. Select 'Continue' once the installation has completed.
