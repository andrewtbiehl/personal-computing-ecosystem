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

- "Target" OS: Debian 13 (Trixie).

## Procedure

### Preliminary steps

1. Ensure that the state of the provisioning computer is functionally identical to that
   of a target computer at the conclusion of performing
   [version `v0.3.0`](https://github.com/andrewtbiehl/personal-computing-ecosystem/tree/v0.3.0)
   of this procedure.
   - *This may or may not require "bootstrapping" the state of the provisioning computer
     via an earlier version of this procedure.*
2. Clone this repository to the home directory on the provisioning computer.
3. Download the target OS disk image to this repository on the provisioning computer via
   the following command.
   ```sh
   wget --output-document=$HOME/personal-computing-ecosystem/debian.iso \
     https://cdimage.debian.org/cdimage/archive/13.5.0/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso
   ```
   - *Debian version 13.5.0 is pinned for reproducibility purposes.*
4. Build the live OS disk image on the provisioning computer via the following command.
   ```sh
   nix build ~/personal-computing-ecosystem/auto-exec-os \
     --extra-experimental-features "nix-command flakes"
   ```
   - *The disk image will now be located at `~/result/iso/`.*
5. Connect the thumb drive to the provisioning computer and write the live OS disk image
   onto the thumb drive.
   1. Open the GNOME Disks application.
   2. Connect the thumb drive and select it inside GNOME Disks.
   3. Click "Drive Options" ("&#8942;" icon) and then click "Restore Disk Image...".
   4. Select the disk image file as the "Image to Restore", click "Start Restoring...",
      and click "Restore".
   5. Click "Power off this disk" ("&#9211;" icon).
   6. Remove the thumb drive.
6. Set up offline "netboot" installation of the target OS disk image.
   1. Download the target OS netboot installer kernel and initial ramdisk via the
      following command.
      ```sh
      wget --directory-prefix=$HOME/personal-computing-ecosystem/ \
        https://snapshot.debian.org/archive/debian/20260707T021943Z/dists/trixie/main/installer-amd64/20250803+deb13u5/images/netboot/debian-installer/amd64/linux \
        https://snapshot.debian.org/archive/debian/20260707T021943Z/dists/trixie/main/installer-amd64/20250803+deb13u5/images/netboot/debian-installer/amd64/initrd.gz
      ```
   2. Extract the target OS disk image contents and make them writable via the following
      command.
      ```sh
      mkdir ~/personal-computing-ecosystem/debian-iso \
          ~/personal-computing-ecosystem/temp \
        && sudo mount ~/personal-computing-ecosystem/debian.iso \
          ~/personal-computing-ecosystem/temp \
        && cp --recursive ~/personal-computing-ecosystem/temp/* \
          ~/personal-computing-ecosystem/debian-iso/ \
        && chmod --recursive u+rw ~/personal-computing-ecosystem/debian-iso \
        && sudo umount ~/personal-computing-ecosystem/temp \
        && rmdir ~/personal-computing-ecosystem/temp
      ```
   3. Ensure that no driver files are missing from the disk image contents by
      downloading all installer micro packages, via the following command.
      ```sh
      wget --output-document=- \
          https://snapshot.debian.org/archive/debian/20260707T021943Z/dists/trixie/main/debian-installer/binary-amd64/Packages.gz \
        | zgrep "^Filename:" \
        | awk '{print "https://snapshot.debian.org/archive/debian/20260707T021943Z/" $2}' \
        | wget \
          --directory-prefix=$HOME/personal-computing-ecosystem/debian-iso/pool/main/netboot-udebs \
          --input-file=-
      ```
   4. Update the disk image's repository metadata to register the new packages, via the
      following command.
      ```sh
      (cd ~/personal-computing-ecosystem/debian-iso \
          && apt-ftparchive packages pool/main/netboot-udebs \
          > dists/trixie/main/debian-installer/binary-amd64/Packages) \
        && gzip --no-name --keep --force \
            ~/personal-computing-ecosystem/debian-iso/dists/trixie/main/debian-installer/binary-amd64/Packages \
        && (cd ~/personal-computing-ecosystem/debian-iso/dists/trixie \
          && apt-ftparchive \
            --config-file ~/personal-computing-ecosystem/release.conf \
            release . > Release)
      ```
   5. Generate a dummy signing key and sign the modified disk image repository metadata,
      via the following command.
      ```sh
      mkdir --mode=700 ~/personal-computing-ecosystem/gnupg \
        && gpg --faked-system-time "20260708T000000" \
          --homedir ~/personal-computing-ecosystem/gnupg --batch --passphrase '' \
          --quick-generate-key "Local Debian Mirror" \
        && gpg --faked-system-time "20260708T000100" \
          --homedir ~/personal-computing-ecosystem/gnupg --batch --yes \
          --output ~/personal-computing-ecosystem/debian-iso/dists/trixie/Release.gpg \
          --detach-sign ~/personal-computing-ecosystem/debian-iso/dists/trixie/Release \
        && gpg --faked-system-time "20260708T000100" \
          --homedir ~/personal-computing-ecosystem/gnupg --batch --yes \
          --output ~/personal-computing-ecosystem/debian-iso/dists/trixie/InRelease \
          --clearsign ~/personal-computing-ecosystem/debian-iso/dists/trixie/Release
      ```
      - *Faking the system time is done for reproducibility purposes; the specific time
        is chosen to be approximately a day after the chosen Debian snapshot time.*
   - *The choice to use the Debian snapshot time of `20260707T021943Z` was vaguely
     influenced by the fact that the current target OS disk image version (i.e. version
     13.5.0) used in this documentation was the latest such version until a few days
     later on 2026-07-11, but is also a rather arbitrary choice.*

### Installation steps

1. Perform the following steps on the provisioning computer.
   1. Ensure the computer is disconnected from the internet.
   2. Connect one compatible Ethernet adapter to the computer.
   3. Open a new shell session to start up a DHCP server bound to the Ethernet adapter
      interface.
      1. Run the following command to determine the name assigned to the adapter
         interface.
         ```sh
         ip address show
         ```
         We hereafter refer to this name via the placeholder `<interface-name>`.
      2. Run the following command to assign the static IP address `192.168.1.1` to the
         adapter interface.
         ```sh
         sudo ip address add 192.168.1.1/24 dev <interface-name> \
           && sudo ip link set dev <interface-name> up
         ```
      3. Start up the DHCP server via the following command.
         ```sh
         sudo dnsmasq \
           --interface=<interface-name> \
           --dhcp-boot=http://192.168.1.1:8000/preseed.txt \
           --dhcp-range=192.168.1.2,192.168.1.2 \
           --dhcp-leasefile=/tmp/dnsmasq.leases \
           --no-daemon
         ```
      - *After completing these steps, remember to shut down the DHCP server and then
        reset the adapter interface configuration via the following command.*
        ```sh
        sudo rm /tmp/dnsmasq.leases \
          && sudo ip address delete 192.168.1.1/24 dev <interface-name>
        ```
   4. Open a new shell session and start up an HTTP server that serves the contents of
      this repository via the following command.
      ```sh
      python3 -m http.server --directory ~/personal-computing-ecosystem
      ```
      - *Remember to shut down the HTTP server after completing these steps.*
2. Perform the following steps on the (initially powered off) target computer.
   1. Follow [Apple's official directions](https://support.apple.com/en-us/102539) to
      reset NVRAM and then power off the computer again.
   2. Connect the target computer to the provisioning computer via the Ethernet cable
      and adapters.
   3. Insert the bootable thumb drive into the computer.
   4. Press the power button while holding down the `option`/`alt` key to start up the
      computer and enter the boot manager.
   5. Select any of the external drive options labeled "EFI Boot" (represented by yellow
      drive icons).
      - *All options are functionally identical; if there is more than one, choose the
        left-most option for consistency.*
3. On the provisioning computer, open a new shell session and perform the following
   steps to trigger the automatic OS installation (on the target computer).
   1. Remotely log in to the target computer's root user environment by running the
      following command, and subsequently entering the live OS root password,
      "password".
      ```sh
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        root@192.168.1.2
      ```
   2. Run the following command to identify the internal drive block device name
      (e.g. `/dev/sda` or `/dev/nvme0n1`) and then determine the corresponding first
      partition name (e.g. `/dev/sda1` or `/dev/nvme0n1p1`, respectively).
      ```sh
      lsblk
      ```
      We hereafter refer to the block device name and corresponding first partition
      name via the placeholders `<device-name>` and `<partition-name>`, respectively.
   3. Run the following command.
      ```sh
      wipefs --all <device-name> \
        && sgdisk --zap-all <device-name> \
        && sgdisk --new=1:0:+512M --typecode=1:EF00 <device-name> \
        && udevadm settle \
        && mkfs.vfat <partition-name> \
        && mount --mkdir <partition-name> /mnt/efi \
        && curl --remote-name-all --output-dir /mnt/efi \
             http://192.168.1.1:8000/linux \
             http://192.168.1.1:8000/initrd.gz \
        && bootctl --esp-path=/mnt/efi install
      ```
      This wipes the internal drive of all filesystems and partition tables, creates
      and formats a new EFI System Partition on the drive, downloads the netboot
      kernel and initial ramdisk to the partition, and installs the systemd-boot
      bootloader on the partition and registers it with NVRAM.
   4. Create the default boot entry configuration file via the following command.
      ```sh
      cat << 'EOF' > /mnt/efi/loader/entries/default.conf
      linux /linux
      initrd /initrd.gz
      options auto=true priority=critical --- intel_iommu=off
      EOF
      ```
   5. Restart the computer via the following command.
      ```sh
      reboot
      ```
   - *Once the installation has completed, the target computer will power off.*
4. Perform the following steps on the target computer.
   1. Start up the computer and log in.
   2. Grant administrative privileges to the initial user.
      1. Add the initial user to the `sudo` group via the following command.
         ```sh
         su --login root --command="usermod --append --groups sudo andrew"
         ```
      2. Log out and log back in.
   3. Run the following command to identify the boot number of the "Linux Boot Manager"
      boot entry.
      ```sh
      efibootmgr
      ```
      We hereafter refer to this boot number via the placeholder `<boot-number>`.
   4. Remove the "Linux Boot Manager" boot entry via the following command.
      ```sh
      sudo efibootmgr --bootnum <boot-number> --delete-bootnum
      ```
   5. Deactivate the temporary software repository configuration used to install the
      target OS, via the following command.
      ```sh
      sudo rm /etc/apt/sources.list
      ```
   6. Set up software repositories for the APT package manager via the following
      command.
      ```sh
      sudo cp /usr/share/doc/apt/examples/debian.sources \
        /etc/apt/sources.list.d/debian.sources
      ```
   7. Connect the computer to the router via the Ethernet cable and compatible adapter.
   8. Set up wireless networking capability.
      1. Install all necessary packages via the following command.
         ```sh
         sudo apt-get update \
           && sudo apt-get install --assume-yes \
             linux-image-amd64 linux-headers-amd64 broadcom-sta-dkms
         ```
      2. Log out, restart the computer, and log in.
      - *The Ethernet connection can now be replaced with a wireless connection.*
   9. Install the Nix package manager via the command
      ```sh
      curl --proto '=https' --tlsv1.2 \
        https://releases.nixos.org/nix/nix-2.35.1/install | sh -s -- --daemon
      ```
      and subsequently typing in your password as prompted.
      - *This command is essentially
        [the official Linux multi-user installation command](https://nixos.org/download/#nix-install-linux),
        pinned to Nix version 2.35.1 for reproducibility purposes.*

## Notes

- ***SECURITY WARNING**: Both the root and new user passwords have been hard coded as
  'password'. This is a weak password choice. Moreover, it is obviously not a good
  practice to use the same password as both the root and new user password. Both
  practices should be avoided in any production setting.*
