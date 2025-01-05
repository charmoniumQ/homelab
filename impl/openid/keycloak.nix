{ config, ... }: let
  defaultApex = config.endOptions.dns.defaultApex;
in {
  imports = [
    ../sql.nix
    ../reverse-proxy.nix
    ../dns.nix
  ];
  services = {
    keycloak = {
      enable = true;
      database = {
        createLocally = true;
        type = {
          postgres = "postgresql";
        }."${config.paas.sql.provider}";
        port = config.paas.sql.port;
      };
      settings = {
        hostname = "https://keycloak.${defaultApex}";
        hostname-strict-https = false;
        http-port = 37112; # ./string_to_port.py keycloak
        http-enabled = true;
        # https://www.keycloak.org/server/hostname#_using_a_reverse_proxy
        proxy-headers = "xforwarded";
      };
    };
  };
  paas = {
    reverseProxy = {
      domains = {
        "keycloak.${defaultApex}" = {
          reverseProxy = {
            port = config.services.keycloak.settings.http-port;
          };
        };
      };
    };
  };
}
