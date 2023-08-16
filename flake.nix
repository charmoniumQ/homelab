{
  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs;
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = { self, nixpkgs, agenix, nixos-generators, ... }:
    let
      hosts = [ "home-server" ];
    in rec {
      packages = {
        x86_64-linux = builtins.listToAttrs (builtins.map (host: {
          name = "${host}-qemu";
          value = self.nixosConfigurations.${host}.config.system.build.vm;
        }) hosts);
      };

      # https://github.com/LongerHV/nixos-configuration/tree/e4a0a7e1018195f29d027b178013061efb5a8f8a/modules/nixos/homelab
      nixosConfigurations = builtins.listToAttrs (builtins.map (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            agenix.nixosModules.default
            ./base.nix
            ./site.nix
            (./hosts + "/${host}")
          ];
        };
      }) hosts);
    };
}
# rsync -avz ../homelab sysadmin@10.0.0.12: && ssh -t sysadmin@10.0.0.12 env --chdir=homelab sudo nixos-rebuild switch --flake .#home-server
