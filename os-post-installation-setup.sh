#!/bin/sh

# Add the initial user to the `sudo` group, remove the "Linux Boot Manager"
# boot entry, deactivate the temporary software repository configuration used
# to install the target OS, set up software repositories for the APT package
# manager, disable password-based remote access, download and install Nix, and
# finally power off the target computer.
usermod --append --groups sudo andrew \
  && efibootmgr --delete-bootnum \
    --bootnum $(efibootmgr | grep "Linux Boot Manager" | cut --characters=5-8) \
  && rm /etc/apt/sources.list \
  && cp /usr/share/doc/apt/examples/debian.sources \
    /etc/apt/sources.list.d/debian.sources \
  && sed --in-place 's/^PermitRootLogin yes/#PermitRootLogin prohibit-password/' \
    /etc/ssh/sshd_config \
  && curl http://192.168.1.1:8000/nix-2.35.1-x86_64-linux.tar.xz \
    | tar --extract --xz --directory /tmp \
  && /tmp/nix-2.35.1-x86_64-linux/install --daemon --yes \
  && rm --recursive --force /tmp/nix-2.35.1-x86_64-linux \
  && poweroff
