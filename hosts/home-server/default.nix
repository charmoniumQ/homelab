{ config, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../site.nix
    ../../lib
  ];
  automaticMaintenance = {
    enable = true;
    time = "Sat, 04:30:00 America/Chicago";
  };
  services = {
    nginx = {
      enable = false;
    };
    caddy = {
      enable = true;
    };
    prometheus = {
      enable = true;
    };
    grafana = {
      enable = true;
        settings = {
          server = {
            domain = "grafana.${config.networking.domain}";
            http_port = 23432;
          };
        };
      # TODO: make alerting-contact-points.json private
    };
    nextcloud = {
      enable = true;
      hostName = "nextcloud.${config.networking.domain}";
      config = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
        adminpassFile = config.age.secrets.nextcloud-adminpass.path;
      };
      smtp = {
        enable = true;
        security = "ssl";
        authentication = true;
        passwordJsonFile = config.age.secrets.nextcloud-smtp-pass.path;
        host = "mail.runbox.com";
        port = 465;
        fromUser = "sam";
        fromDomain = "samgrayson.me";
      };
    };
  };
  age = {
    secrets = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
      nextcloud-smtp-pass = {
        file = ../../secrets/nextcloud-smtp-pass.age;
        owner = config.services.phpfpm.pools.nextcloud.user;
        group = config.services.phpfpm.pools.nextcloud.group;
      };
      nextcloud-adminpass = {
        file = ../../secrets/nextcloud-adminpass.age;
        owner = config.services.phpfpm.pools.nextcloud.user;
        group = config.services.phpfpm.pools.nextcloud.group;
      };
    };
  };
}
