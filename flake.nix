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
  outputs = { self, nixpkgs, agenix, nixos-generators, ... }@inputs:
    {
      packages = {
        x86_64-linux = {
          home-server-qemu = self.nixosConfigurations.home-server.config.system.build.vm;
        };
      };

      nixopsConfigurations = {
        default = {
          inherit nixpkgs;
          network = {
            description = "My homelab network.";
            storage = {
              legacy = {
                databasefile = "~/.local/share/nixops/deployments.nixops";
              };
            };
          };
          home-server = {config, ...}@attrs: ((import ./hosts/home-server) (attrs // { pkgs = nixpkgs; })) // {
            deployment = {
              targetHost = config.localIP;
              targetUser = config.sysadmin.username;
            };
          };
        };
      };

      # https://github.com/LongerHV/nixos-configuration/tree/e4a0a7e1018195f29d027b178013061efb5a8f8a/modules/nixos/homelab
      nixosConfigurations = {
        home-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [ ./hosts/home-server ];
        };
      };
    };
}
# rsync -avz ../homelab sysadmin@10.0.0.12: && ssh -t sysadmin@10.0.0.12 env --chdir=homelab sudo nixos-rebuild switch --flake .#home-server
