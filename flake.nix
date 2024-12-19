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
    nix-alien = {
      url = github:thiagokokada/nix-alien;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = { self, nixpkgs, agenix, flake-utils, disko, nixos-anywhere, nixos-generators, ... }@inputs:
    let
      hosts = [
         "home-server"
         "cloud-server"
         "laptop"
         "tvpi"
       ];
    in
     nixpkgs.lib.attrsets.recursiveUpdate
       ((import ./mkHosts.nix) inputs hosts)
       (flake-utils.lib.eachDefaultSystem (system:
         let
           pkgs = nixpkgs.legacyPackages.${system};
           mkApp = string: {
             type = "app";
             program = let
               package = pkgs.writeShellScriptBin "script" ''
                 set -eux -o pipefail -o noclobber
                 ${string}
               '';
             in "${package}/bin/script";
           };
         in {
           apps = {
             image-tvpi   = mkApp "${pkgs.nom}/bin/nom build --verbose --show-trace .#nixosConfigurations.tvpi.config.system.build.sdImage";
             edit-secret = mkApp ''
               fname=$1
               shift
               env --chdir=secrets/ ${agenix.packages.x86_64-linux.default}/bin/agenix -e $fname $@
             '';
             check = mkApp ''
               ${pkgs.statix}/bin/statix check .
             '';
           };
           devShells = {
             default = pkgs.mkShell {
               packages = [
                 pkgs.pv # for flashing SD cards
                 pkgs.pwgen
                 pkgs.apacheHttpd # for htpasswd
                 pkgs.restic # for reading backups
                 pkgs.nixos-rebuild # latest version
                 pkgs.nix-output-monitor
                 pkgs.nh
                 disko.packages."${system}".default
                 agenix.packages."${system}".default
                 nixos-anywhere.packages."${system}".default
                 nixos-generators.packages."${system}".default
                 (pkgs.python311.withPackages (pypkgs: [
                   pypkgs.mypy
                   pypkgs.types-retry
                   pypkgs.types-requests
                   pypkgs.black
                 ])) # for the scripts in this repo
               ];
             };
           };
         }
       ))
  ;
}
