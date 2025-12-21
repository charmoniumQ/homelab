{
  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs/nixos-unstable;
    };
    sops-nix = {
      url = github:Mic92/sops-nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selfhostblocks = {
      url = "github:ibizaman/selfhostblocks";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    agenix = {
      url = github:ryantm/agenix;
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "flake-utils/systems";
      };
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
    };
  };
  outputs = {
    self
    , nixpkgs
    , agenix
    , flake-utils
    , disko
    , nixos-anywhere
    , nixos-generators
    , sops-nix
    , selfhostblocks
    , ...
  }@inputs:
    let
      hosts = [
        "home-server"
        "cloud-server"
        "laptop"
        "tvpi"
      ];
      nixlib = import ./nixlib.nix {
        inherit (nixpkgs) lib;
        inherit (nixpkgs) system;
      };
      inputs' = inputs // { inherit nixlib; };
    in
     nixpkgs.lib.attrsets.recursiveUpdate
       ((import ./mkHosts.nix) inputs' hosts)
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
             check = mkApp ''
               ${pkgs.statix}/bin/statix check .
             '';
           };
           devShells = {
             default = pkgs.mkShell {
               packages = [
                 pkgs.restic # for reading backups
                 pkgs.nixos-rebuild # latest version
                 agenix.packages.${system}.default
                 nixos-generators.packages.${system}.default
                 sops-nix.packages.${system}.default
                 (pkgs.python311.withPackages (pypkgs: [
                   pypkgs.mypy
                   pypkgs.types-retry
                   pypkgs.types-requests
                   pypkgs.black
                 ])) # for the scripts in this repo
               ];
               sopsPGPKeyDirs = [
                 "${toString ./.}/public_keys/hosts"
                 "${toString ./.}/public_keys/users"
               ];
               nativeBuildInputs = [
                 sops-nix.packages.${system}.sops-import-keys-hook
               ];
             };
           };
         }
       ))
  ;
}
