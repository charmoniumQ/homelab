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
      # packages = {
      #   x86_64-linux = builtins.listToAttrs (builtins.map (host: {
      #     name = "${host}-qemu";
      #     value = nixos-generators.nixosGenerate {
      #       system = "x86_64-linux";
      #       modules = [ self.nixosConfigurations.${host}.modules ];
      #       format = "vm";
      #     };
      #   }) hosts);
      # };
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
