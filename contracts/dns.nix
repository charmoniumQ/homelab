{ lib, pkgs, selfhostblocks, system, ... }:
let
  domain-name = ../nixlib/domain-name.nix lib;
in {
  options.shb.contracts.dns = lib.mkOption {
    description = ''
      Contract for assigning DNS records.

      This may be filled directly by the supplier, in the case of a self-hosted
      authoritative name-server, or it may be simply a consolidate list of
      records that need to be created before deployment.

      In the latter case, perhaps a script could enumerate the contract requests
      and send API requests for any newly requested DNS records, impurely but at
      least declaratively.
    '';
    type = lib.types.submodule {
      # options =
    };
  };
}
