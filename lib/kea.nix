{ pkgs, lib, config, ... }:
let
  cfg = config.services.dhcp-server;
in {
  config = {
    services = {
      kea = lib.attrsets.optionalAttrs (cfg.enable && cfg.implementation == "kea") {
        dhcp4 = {
          enable = true;
          settings = {
            interfaces-config = {
              interfaces = [ cfg.interface ];
            };
            lease-database = {
              name = "/var/lib/kea/dhcp4.leases";
              persist = true;
              type = "memfile";
            };
            authoritative = true;
            valid-lifetime = 8000;
            rebind-timer = 4000;
            renew-timer = 2000;
            subnet4 = [
              {
                pools = [
                  {
                    pool = "192.168.1.32 - 192.168.1.254";
                  }
                ];
                subnet = "192.168.1.0/24";
              }
            ];
            option-data = [
              {
                name = "domain-name-servers";
                csv-format = true;
                data ="${config.localIP},1.1.1.1,1.0.0.1";
              }
              # {
              #   name = "ntp-servers";
              #   data ="${config.localIP}";
              # }
              {
                name = "routers";
                data = "192.168.1.1";
              }
            ];
          };
        };
      };
    };
    networking = {
      interfaces = {
        "${cfg.interface}" = {
          ipv4 = {
            addresses = [{
              address = config.localIP;
              prefixLength = 24;
            }];
          };
        };
      };
      firewall = {
        allowedUDPPorts = [ 67 68 ];
      };
    };
  };
  options = {
    services = {
      dhcp-server = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to enable a DHCP server";
          default = false;
        };
        implementation = lib.mkOption {
          type = lib.types.enum [ "kea" ];
          default = "kea";
        };
        interface = lib.mkOption {
          type = lib.types.str;
        };
      };
    };
  };
}
