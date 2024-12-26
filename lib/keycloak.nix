{ config, ... }:
{
  services = {
    keycloak = {
      enable = true;
      database = {
        createLocally = true;
        type = "postgresql";
        port = config.services.postgresql.settings.port;
      };
      settings = {
        hostname = "https://keycloak.${config.networking.domain}";
        hostname-strict-https = false;
        http-port = 38513;
        http-enabled = true;
        # https://www.keycloak.org/server/hostname#_using_a_reverse_proxy
        proxy-headers = "xforwarded";
      };
    };
  };
  reverseProxy = {
    domains = {
      "${builtins.elemAt (builtins.split "://" config.services.keycloak.settings.hostname) 2}" = {
        port = config.services.keycloak.settings.http-port;
      };
    };
  };
}
