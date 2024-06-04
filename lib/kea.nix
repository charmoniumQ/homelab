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
                data ="${config.localIP}";
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
        ctrl-agent = {
          enable = false;
          # enable = true;
          # configFile = config.generatedFiles.kea-ctrl-agent-settings.path;
        };
      };
    };
    networking = lib.attrsets.optionalAttrs (cfg.enable && cfg.implementation == "kea") {
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
      defaultGateway = {
        address = "192.168.1.1";
        interface = cfg.interface;
      };
      firewall = {
        allowedUDPPorts = [ 67 68 ];
      };
    };
    # generatedFiles = {
    #   kea-ctrl-agent-settings = {
    #     name = "kea-ctrl-agent-settings.json";
    #     script = let
    #       settings = (pkgs.formats.json {}).generate "cfg.json" {
    #         Control-agent = {
    #           http-host = "127.0.0.1";
    #           http-port = 59843;
    #           authentication = {
    #             type = "basic";
    #             realm = "kea-control-agent";
    #             clients = [ {
    #               user = "admin";
    #               password = "password_goes_here";
    #             } ];
    #           };
    #         };
    #         control-sockets = {
    #           dhcp4 = {
    #             comment = "main server";
    #             socket-type = "unix";
    #             socket-name = "/path/to/the/unix/socket-v4";
    #           };
    #         };
    #       };
    #       pwfile = config.services.kea.ctrl-agent.pass-file;
    #     in
    #       ''${pkgs.gnused}/bin/sed "s/password_goes_here/$(cat ${pwfile})/g" ${settings}'';
    #   };
    # };
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
      kea = {
        ctrl-agent = {
          pass-file = lib.mkOption {
            type = lib.types.path;
            description = "Password must NOT contain slashes!";
          };
        };
      };
    };
  };
}
