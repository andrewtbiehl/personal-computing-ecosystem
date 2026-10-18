{
  description = "Basic live OS";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = self.nixosConfigurations.liveOS.config.system.build.isoImage;
    nixosConfigurations = {
      liveOS = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            # Set a dummy password to enable remote SSH access.
            users.users.root.password = "password";
          })
        ];
      };
    };
  };
}
