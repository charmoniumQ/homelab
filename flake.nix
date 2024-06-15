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
    nixos-hardware = {
      url = github:NixOS/nixos-hardware;
    };
    nixos-anywhere = {
      url = github:nix-community/nixos-anywhere;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };
  };
  outputs = { self, nixpkgs, agenix, flake-utils, disko, nixos-anywhere, nixos-generators, ... }@inputs:
    ((import ./mkHosts.nix) inputs [
      "home-server"
      "cloud-server"
      "laptop"
      "tvpi"
    ]) // flake-utils.lib.eachDefaultSystem (system:
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
          apply-cloud  = mkApp "     nixos-rebuild switch --verbose --show-trace --flake '.#cloud-server' --target-host 'sysadmin@cloud.samgrayson.me' --use-remote-sudo";
          apply-home   = mkApp "     nixos-rebuild switch --verbose --show-trace --flake '.#home-server'  --target-host 'sysadmin@home.samgrayson.me'  --use-remote-sudo";
          apply-laptop = mkApp "sudo nixos-rebuild switch --verbose --show-trace --flake '.#laptop'";
          apply-tvpi   = mkApp "     nixos-rebuild switch --verbose --show-trace --flake '.#tvpi'         --target-host 192.168.1.17                   --use-remote-sudo";
          image-tvpi   = mkApp "nix build --verbose --show-trace .#nixosConfigurations.tvpi.config.system.build.sdImage";
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
              pkgs.pv # for flashing SD cards
              pkgs.pwgen
              pkgs.apacheHttpd # for htpasswd
              pkgs.restic
              pkgs.nixos-rebuild
              disko.packages."${system}".default
              agenix.packages."${system}".default
              nixos-anywhere.packages."${system}".default
              nixos-generators.packages."${system}".default
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
