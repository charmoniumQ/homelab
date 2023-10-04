{ config, lib, ... }:
let
  secrets = config.age.secrets;
in {
  imports = [
    ./hardware-configuration.nix
    ../site.nix
  ];
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
      # TODO: make alerting-contact-points.json private
    };
    nextcloud = {
      enable = true;
      config = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
        adminpassFile = secrets.nextcloudAdminpass.path;
      };
    };
    vaultwarden = {
      enable = true;
      admin_token_file = secrets.vaultwarden-admin-token.path;
    };
    home-assistant = {
      enable = true;
    };
    dyndns = {
      entries = [
        {
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          host = "*";
          passwordFile = secrets.namecheapPassword.path;
        }
      ];
    };
  };
  backups = {
    enable = true;
    passwordFile = secrets.resticPassword.path;
    environmentFile = secrets.resticEnvironmentFile.path;
    remoteRepo = "b2:charmonium-backups:home-server";
  };
  dns = { # TODO: rename dns -> localDns
    localDomains = [
      "home.samgrayson.me"
      # Note that reverse proxy domains are already added
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
      namecheapPassword = {
        file = ../../secrets/namecheapPassword.age;
      };
      resticPassword = {
        file = ../../secrets/resticPassword.age;
      };
      resticEnvironmentFile = {
        file = ../../secrets/restic.env.age;
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
