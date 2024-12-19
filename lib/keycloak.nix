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
      initialAdminPassword = "8DeEyOrGIPuf98ExhczSWFt0DYfZwznFqTTo2nkLhZOpfTB9a3bEpqd8cYA4XaIu"; # changed on first login
    };
  };
  reverseProxy = {
    domains = {
      "${config.services.keycloak.settings.hostname}" = {
        port = config.services.keycloak.settings.http-port;
      };
    };
  };
}
