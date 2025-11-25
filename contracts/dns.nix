{ lib, pkgs, selfhostblocks, system, ... }:
let
  domain-name = ../nixlib/domain-name.nix lib;
in {
  contracts = {
    dns = {
      meta = {
        maintainers = [ lib.maintainers.charmoniumQ ];
        description = ''
          Contract for assigning DNS records.

          Some examples of possible providers:

          - A self-hosted authoritative name-server configured to serve the requested records.

          - A SystemD service that uses the extenral DNS registrar's client API to register the requested records.  

          - A message that gets printed on-build, instructing the user to create the DNS records.

        '';
      };
      input = {
        options = {
          records = null;
        };
      };
      output = {
        options = {
          records = null;
        };
      };
    };
  };
}
