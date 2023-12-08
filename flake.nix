{
  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs/nixos-unstable;
    };
    agenix = {
      url = github:ryantm/agenix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = github:numtide/flake-utils;
    };
    disko = {
      url = github:nix-community/disko;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefly = {
      url = github:timhae/firefly;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = github:NixOS/nixos-hardware;
    };
  };
  outputs = { self, nixpkgs, agenix, flake-utils, disko, ... }@inputs:
    ((import ./mkHosts.nix) inputs {
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ ];
          };
          specialArgs = inputs;
        };
        home-server = {
          deployment = {
            targetHost = "home.samgrayson.me";
            targetUser = "sysadmin";
          };
        };
        laptop = {
          deployment = {
            # Allow local deployment with `colmena apply-local`
            allowLocalDeployment = true;

            # Disable SSH deployment. This node will be skipped in a
            # normal`colmena apply`.
            targetHost = null;
          };
        };
      };
    })
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        apps = {
          apply = {
            type = "app";
            program = let
              package = pkgs.writeShellScriptBin "script" "${pkgs.colmena}/bin/colmena apply --show-trace --verbose";
            in "${package}/bin/script";
          };
          edit-secret = {
            type = "app";
            program = let
              package = pkgs.writeShellScriptBin "script" ''
                set -xx
                fname=$1
                shift
                env --chdir=secrets/ ${agenix.packages.x86_64-linux.default}/bin/agenix -e $fname $@
              '';
            in "${package}/bin/script";
          };
        };
        devShells = {
          default = pkgs.mkShell {
            packages = [
              pkgs.colmena
              pkgs.pwgen
              pkgs.apacheHttpd # for htpasswd
              disko.packages."${system}".default
              agenix.packages."${system}".default
              (pkgs.python311.withPackages (pypkgs: [
                pypkgs.mypy
                pypkgs.types-retry
                pypkgs.types-requests
                pypkgs.black
              ]))
            ];
          };
        };
      }
    )
  ;
}
