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
      port = lib.trivial.warn "Move this port number to a hash" 24712;
    };
    grafana = {
      enable = true;
        settings = {
          server = {
            http_port = lib.trivial.warn "Move this port number to a hash" 23432;
          };
        };
      # TODO: make alerting-contact-points.json private
    };
    nextcloud = {
      enable = true;
      config = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
        adminpassFile = config.age.secrets.nextcloudAdminpass.path;
      };
    };
    vaultwarden = {
      enable = true;
      admin_token_file = config.age.secrets.vaultwarden-admin-token.path;
    };
    home-assistant = {
      enable = true;
    };
  };
  dns = {
    localDomains = [
      "home.samgrayson.me"
    ];
  };
  age = {
    secrets = {
      smtpPass = {
        file = ../../secrets/smtp-pass.age;
      };
      locationJson = {
        file = ../../secrets/location.json.age;
      };
    } // lib.attrsets.optionalAttrs config.services.nextcloud.enable {
      nextcloudAdminpass = {
        file = ../../secrets/nextcloud-adminpass.age;
        owner = config.services.phpfpm.pools.nextcloud.user;
        group = config.services.phpfpm.pools.nextcloud.group;
      };
    } // lib.attrsets.optionalAttrs config.services.vaultwarden.enable {
      vaultwarden-admin-token = {
        file = ../../secrets/vaultwarden-admin-token.age;
      };
    };
  };
}
