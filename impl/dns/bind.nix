{ config, lib, ... }: let
  domainName = (import nixlib/domain-name.nix) lib;
in {
  config = {
    services = {
      bind = {
        enable = true;
        zones = builtins.listToAttrs (builtins.map (zone: {
          name = zone;
          value = {
            master = true;

          };
        }) config.endOptions.domainZones);
      };
    };
  };
  options = {
    endOptions = {
      dns = {
        domainZones = lib.mkOption {
          type = lib.types.listOf domainName;
        };
        ANamesToSelf = lib.mkOption {
          type = lib.types.listOf domainName;
        };
        otherRecords = lib.types.attrsOf (lib.submodule ({name, ...}: {
          options = {
            recordType = lib.mkOption {
              type = lib.types.enum [ "A" "CNAME" ];
            };
            key = lib.mkOption {
              type = domainName;
            };
            value = lib.mkOption {
              type = lib.types.str;
            };
          };
        }));
      };
    };
  };
}
