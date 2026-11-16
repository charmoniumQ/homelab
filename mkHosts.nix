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
  hostSystem = {
    home-server = "x86_64-linux";
    cloud-server = "aarch64-linux";
    laptop = "x86_64-linux";
    tvpi = "aarch64-linux";
  };
  nixosConfigurations = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host:
    let
      system = hostSystem.${host};
    in {
      name = "${host}";
      value = nixpkgs.lib.nixosSystem {
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
    defaultBuildMode = if hostSystem.${host} != system then "remote" else "local";
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
          buildMode=${defaultBuildMode}
          usage() {
            echo "Usage: $0 [--skip] [--local|--remote]"
            echo "  -s, --skip  skip the build step"
            echo "  --local     build on this machine (binfmt for cross-system)"
            echo "  --remote    build on the configured remote builder"
          }
          while [[ $# -gt 0 ]]; do
            case $1 in
              -s|--skip)
                skip_nom=1
                shift
                ;;
              --local)
                buildMode=local
                shift
                ;;
              --remote)
                buildMode=remote
                shift
                ;;
              -h|--help)
                usage
                exit 0
                ;;
              *)
                echo "Unknown arg: $1"
                usage
                exit 1
                ;;
            esac
          done
          if [ -z "$skip_nom" ]; then
            buildArgs=()
            if [ "$buildMode" = remote ]; then
              buildArgs+=(--max-jobs 0 --option builders-use-substitutes true)
            else
              buildArgs+=(--option builders "")
            fi
            ${pkgs.nix-output-monitor}/bin/nom build \
              "''${buildArgs[@]}" \
              --verbose \
              ".#nixosConfigurations.${host}.config.system.build.toplevel"
          fi
          ${sudo} nixos-rebuild switch --verbose --show-trace --flake ".#${host}" ${targetHost} ${useRemoteSudo}
        '';
      in "${p}/bin/script";
    };
  }));
})) // { inherit nixosConfigurations; }
