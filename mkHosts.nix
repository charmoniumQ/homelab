/*
Turns a simple object into QEMU VMs and nixosConfigurations.
*/
{ nixpkgs, flake-utils, ... }@flake-inputs: hosts:
let
  lib = nixpkgs.lib;
  importsForHost = host: [
    ./hosts/site.nix
    (./hosts + "/${host}")
  ];
  nixosConfigurations = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = "${host}";
    value = nixpkgs.lib.nixosSystem {
      specialArgs = flake-inputs;
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
        useRemoteSudo = if cfg.deployment.sudo && cfg.deployment.hostName != "localhost" then "--use-remote-sudo" else "";
        p = pkgs.writeShellScriptBin "script" ''
          set -eux -o pipefail
          ${pkgs.nom}/bin/nom build \
            --verbose \
            ".#nixosConfigurations.${host}.config.system.build.toplevel" \
            -- --show-trace
          ${sudo} nixos-rebuild switch --verbose --show-trace --flake ".#${host}" ${targetHost} ${useRemoteSudo}
        '';
      in "${p}/bin/script";
    };
  }));
})) // { inherit nixosConfigurations; }
