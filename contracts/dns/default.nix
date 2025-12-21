{ lib, pkgs, shb, system, ... }:
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
      domains = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.oneOf [ "A" "AAAA" "CNAME" "TXT" "ALIAS" "MX" "SOA" "SRV" "PTR"];
          };
          key = lib.mkOption {
            type = lib.types.str;
          };
          address = lib.mkOption {
            type = lib.types.str;
          };
          ttl = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
          };
          mx_priority = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
          };
        };
      }));
    };
  };
}
