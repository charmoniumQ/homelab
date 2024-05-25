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
      url = github:charmoniumQ/firefly/patch-2;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = github:NixOS/nixos-hardware;
    };
    pia = {
      url = "git+https://git.sr.ht/~rprospero/nixos-pia?ref=development";
      inputs.nixpkgs.follows = "nixpkgs";
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
        apps = let
          mkApp = string: {
            type = "app";
            program = let
              package = pkgs.writeShellScriptBin "script" string;
            in "${package}/bin/script";
          };
        in {
          colmena = mkApp "${pkgs.colmena}/bin/colmena $@";
          apply-local = mkApp "${pkgs.colmena}/bin/colmena apply-local --sudo --show-trace --verbose --impure $@";
          apply-remote = mkApp "${pkgs.colmena}/bin/colmena apply --show-trace --verbose --impure $@";
          apply-all = mkApp ''
            ${pkgs.colmena}/bin/colmena apply-local --sudo --show-trace --verbose $@
            if ${pkgs.openssh}/bin/ssh sysadmin@home.samgrayson.me true; then
              ${pkgs.colmena}/bin/colmena apply --show-trace --verbose $@
            else
              echo "Can't connect to host sysadmin@home.samgrayson.me"
            fi
          '';
          edit-secret = mkApp ''
            set -xx
            fname=$1
            shift
            env --chdir=secrets/ ${agenix.packages.x86_64-linux.default}/bin/agenix -e $fname $@
          '';
        };
        devShells = {
          default = pkgs.mkShell {
            packages = [
              pkgs.colmena
              pkgs.pwgen
              pkgs.apacheHttpd # for htpasswd
              pkgs.restic
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
