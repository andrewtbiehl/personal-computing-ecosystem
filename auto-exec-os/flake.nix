{
  description = "Live OS with automatically executed networking script";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = self.nixosConfigurations.autoExecOS.config.system.build.isoImage;
    nixosConfigurations = {
      autoExecOS = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            # Main networking script
            environment.etc."main.sh" = {
              mode = "0500";
              text = ''
                #!/bin/sh
                ${pkgs.curl}/bin/curl http://192.168.1.1:8080/preseed.txt
                echo "Shutting computer down in 10 seconds."
                ${pkgs.coreutils}/bin/sleep 10
                poweroff
              '';
            };
            # Systemd service unit file for automatically executing main script
            systemd.units."main.service" = {
              wantedBy = [ "multi-user.target" ];
              text = ''
                [Unit]
                After=network-online.target

                [Service]
                ExecStart=/etc/main.sh
                StandardOutput=tty

                [Install]
                WantedBy=multi-user.target
              '';
            };
          })
        ];
      };
    };
  };
}
