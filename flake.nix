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
  };
  outputs = { self, nixpkgs, agenix, nixos-generators, ... }@inputs: {
    nixosConfigurations = {
      home-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [ ./hosts/home-server ];
      };
    };
    packages = {
      x86_64-linux = {
        home-server-qemu = self.nixosConfigurations.home-server.config.system.build.vm;
      };
    };
    devShells = {
      x86_64-linux = {
        default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = [
            nixpkgs.legacyPackages.x86_64-linux.colmena
            nixpkgs.legacyPackages.x86_64-linux.pwgen
            agenix.packages.x86_64-linux.default
          ];
        };
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
          targetHost = "10.0.0.12";
          # targetHost = "home.samgrayson.me";
          targetUser = "sysadmin";
        };
        imports = [ ./hosts/home-server ];
      };
    };
  };
}
