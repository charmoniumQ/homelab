/*
Turns a simple object into QEMU VMs and nixosConfigurations.
*/
{ nixpkgs, flake-utils, selfhostblocks, ... }@flake-inputs: hosts:
let
  lib = nixpkgs.lib;
  importsForHost = host: [
    ./hosts/site.nix
    (./hosts + "/${host}")
  ];
  nixosConfigurations = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host:
    let
      system = "x86_64-linux";
    in {
      name = "${host}";
      value = nixpkgs.lib.nixosSystem {
      # value = selfhostblocks.lib."${system}".patchedNixpkgs.nixosSystem {
        specialArgs = flake-inputs;
        inherit system;
        modules = importsForHost host;
      };
    }));
in (flake-utils.lib.eachDefaultSystem (system: {
  packages = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host:
  let
    cfg = nixosConfigurations.${host}.config;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    name = "${host}-qemu";
    value = cfg.system.build.vm;
  }));
  apps = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host:
  let
    cfg = nixosConfigurations.${host}.config;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    name = "deploy-${host}";
    value = {
      type = "app";
      program = let
        sudo = if cfg.deployment.sudo && cfg.deployment.hostName == "localhost" then "sudo" else "";
        targetHost = if cfg.deployment.hostName == "localhost" then "" else "--target-host ${cfg.deployment.username}@${cfg.deployment.hostName}";
        useRemoteSudo = if cfg.deployment.sudo && cfg.deployment.hostName != "localhost" then "--sudo" else "";
        p = pkgs.writeShellScriptBin "script" ''
          set -eux -o pipefail
          skip_nom=
          while [[ $# -gt 0 ]]; do
            case $1 in
              -s|--skip)
                skip_nom=1
                shift
                ;;
              *)
                echo 'Unknown arg'
                exit 1
                ;;
            esac
          done
          if [ -z $skip_nom ]; then
            ${pkgs.nix-output-monitor}/bin/nom build \
              --verbose \
              ".#nixosConfigurations.${host}.config.system.build.toplevel"
          fi
          ${sudo} nixos-rebuild switch --verbose --show-trace --flake ".#${host}" ${targetHost} ${useRemoteSudo}
        '';
      in "${p}/bin/script";
    };
  }));
})) // { inherit nixosConfigurations; }
