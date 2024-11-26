{ config, lib, pkgs, disko, modulesPath, ... }:
let
  secrets = config.age.secrets;
in {
  imports = [
    disko.nixosModules.disko
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./hardware-configuration.nix
    ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/backups.nix
    ../../lib/caddy.nix
    ../../lib/dns.nix
    ../../lib/deployment.nix
    ../../lib/dyndns.nix
    ../../lib/externalSmtp.nix
    ../../lib/generatedFiles.nix
    ../../lib/fail2ban.nix
    ../../lib/firefly-iii.nix
    ../../lib/grafana.nix
    ../../lib/grocy.nix
    ../../lib/jupyter.nix
    # ../../lib/home-assistant.nix
    ../../lib/kea.nix
    ../../lib/locale.nix
    ../../lib/loki.nix
    ../../lib/networkedNode.nix
    ../../lib/nextcloud.nix
    ../../lib/nixConf.nix
    ../../lib/runtimeTests.nix
    ../../lib/paperless.nix
    ../../lib/prometheus.nix
    ../../lib/promtail.nix
    ../../lib/reverseProxy.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
    ../../lib/sysadmin.nix
    ../../lib/vaultwarden.nix
    # ../../lib/unbound.nix
  ];
  deployment = {
    sudo = true;
    hostName = "cloud.samgrayson.me";
  };
  sysadmin = {
    hashedPassword = "$y$j9T$QfgpfZwUTsKsyhHUh71aD1$o9OuIHMYXkbUGOFbDaUOouJpnim9aRrX2YmQPYo.N67";
  };
  externalSmtp = {
    enable = true;
    security = "ssl";
    authentication = true;
    passwordFile = config.age.secrets.smtpPass.path;
    host = "mail.runbox.com";
    port = 465;
    fromUser = "sam";
    fromDomain = "samgrayson.me";
    tests = {
      enable = false;
    };
  };
  automaticMaintenance = {
    enable = true;
    weeklyTime = "Sat 03:00:00";
    dailyTime = "02:30:00";
    randomizedDelay = "4h";
  };
  networking = {
    domain = "samgrayson.me";
    enableIPv6 = true;
  };
  services = {
    paperless = {
      enable = true;
      passwordFile = config.age.secrets.paperless-password.path;
    };
    caddy = {
      enable = true;
      virtualHosts = {
        # "home-assistant.samgrayson.me" = {
        #   extraConfig = ''
        #     reverse_proxy https://home-assistant2.samgrayson.me {
        #         header_up Host {upstream_hostport}
        #         header_up X-Forwarded-Host {host}
        #     }
        #   '';
        # };
      };
    };
    prometheus = {
      enable = lib.trivial.warn "Fix this when prometheus blackbox is restored" false;
    };
    grafana = {
      enable = true;
      # TODO: make alerting-contact-points.json private
    };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud30;
      hostName = "nextcloud.samgrayson.me";
      config = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
        adminpassFile = config.age.secrets.nextcloudAdminpass.path;
      };
    };
    jupyter = {
      enable = lib.trivial.warn "Fix this later" false;
    };
    vaultwarden = {
      enable = true;
      domain = "vaultwarden.samgrayson.me";
      admin_token_file = config.age.secrets.vaultwarden-admin-token.path;
    };
    home-assistant = {
      enable = false;
      # hostname = "home-assistant2.samgrayson.me";
      # secretsYaml = config.age.secrets.homeAssistantSecretsYaml.path;
      # zigbee2mqttSecretsYaml = config.age.secrets.zigbee2mqttSecretsYaml.path;
    };
    dyndns = {
      entries = [
        {
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          hosts = [
            "cloud"
            "jupyter"
            "grafana"
            "nextcloud"
            "vaultwarden"
            "home-assistant"
          ] ++ lib.lists.optional config.services.firefly-iii.enable "firefly-iii";
          passwordFile = config.age.secrets.namecheapPassword.path;
        }
      ];
    };
    firefly-iii = {
      enable = false;
      # settings = {
      #   APP_KEY_FILE = config.age.secrets.firefly-iii-app-key.path;
      #   DB_PASSWORD_FILE = config.age.secrets.firefly-iii-postgres.path;
      # };
    };
  };
  environment = {
    systemPackages = [
      pkgs.speedtest-go
      pkgs.mtr
    ];
  };
  backups = {
    enable = false;
    enableTimers = false;
    passwordFile = config.age.secrets.resticPassword.path;
    environmentFile = config.age.secrets.resticEnvironmentFile.path;
    remoteRepo = "b2:charmonium-backups:home-server";
  };
  age = {
    secrets = {
      smtpPass = {
        file = ../../secrets/smtp-pass.age;
        group = "smtp";
        mode = "0440";
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
    } // lib.attrsets.optionalAttrs config.services.home-assistant.enable {
      homeAssistantSecretsYaml = {
        file = ../../secrets/home-assistant-secrets.yaml.age;
        owner = config.users.users.hass.name;
        group = config.users.users.hass.group;
      };
    } // lib.attrsets.optionalAttrs config.services.firefly-iii.enable {
      firefly-iii-app-key = {
        file = ../../secrets/firefly-iii-app-key.age;
        mode = "0400";
        owner = config.services.firefly-iii.user;
        group = config.services.firefly-iii.group;
      };
      firefly-iii-postgres = {
        file = ../../secrets/firefly-iii-postgres.age;
        mode = "0400";
        owner = config.services.firefly-iii.user;
        group = config.services.firefly-iii.group;
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
    } // lib.attrsets.optionalAttrs config.services.paperless.enable {
      paperless-password = {
        file = ../../secrets/paperless.age;
      };
    };
  };
}
