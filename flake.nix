{
  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs/nixos-unstable;
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
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { self, nixpkgs, agenix, nixos-generators, flake-utils, ... }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in {
        packages = {
          # notify_push = pkgs.mkDerivation {
          # };
        };
        devShells = {
          default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
            packages = [
              pkgs.colmena
              pkgs.pwgen
              (pkgs.python311.withPackages (pypkgs: [
                pypkgs.mypy
                pypkgs.types-retry
                pypkgs.types-requests
                pypkgs.black
              ]))
              agenix.packages.x86_64-linux.default
            ];
          };
        };
      })) // {
        nixosConfigurations = {
          home-server = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [ ./hosts/home-server ];
          };
        };
        packages = {
          "x86_64-linux" = {
            home-server-qemu = self.nixosConfigurations."home-server".config.system.build.vm;
          };
        };
        colmena = {
          meta = {
            nixpkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [];
            };
            specialArgs = inputs;
          };
          home-server = {
            deployment = {
              targetHost = "192.168.1.28";
              # targetHost = "home.samgrayson.me";
              targetUser = "sysadmin";
            };
            imports = [ ./hosts/home-server ];
          };
        };
      };
}
