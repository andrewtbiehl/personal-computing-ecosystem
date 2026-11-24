#!/bin/sh

set -e

# Create the initial user account 'andrew' and set the password to 'password'.
adduser --disabled-password --comment "Andrew" andrew
echo "andrew:password" | chpasswd

# Add the initial user to the `sudo` group.
usermod --append --groups sudo andrew

# Remove the "Linux Boot Manager" boot entry.
efibootmgr --delete-bootnum \
  --bootnum $(efibootmgr | grep "Linux Boot Manager" | cut --characters=5-8)

# Install additional software.
apt-get update --allow-insecure-repositories
DEBIAN_FRONTEND=noninteractive apt-get install --yes --allow-unauthenticated \
  curl git linux-image-amd64 linux-headers-amd64 broadcom-sta-dkms

# Deactivate the temporary software repository configuration used to install
# the target OS.
rm /etc/apt/sources.list

# Set up software repositories for the APT package manager.
cp /usr/share/doc/apt/examples/debian.sources \
  /etc/apt/sources.list.d/debian.sources

# Disable password-based remote access.
sed --in-place 's/^PermitRootLogin yes/#PermitRootLogin prohibit-password/' \
  /etc/ssh/sshd_config

# Download and install Nix.
curl http://192.168.1.1:8000/nix-2.35.1-x86_64-linux.tar.xz \
  | tar --extract --xz --directory /tmp
/tmp/nix-2.35.1-x86_64-linux/install --daemon --yes
rm --recursive --force /tmp/nix-2.35.1-x86_64-linux

# Power off the target computer.
poweroff
