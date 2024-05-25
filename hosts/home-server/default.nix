{ config, lib, pkgs, ... }:
let
  secrets = config.age.secrets;
in {
  imports = [
    ./hardware-configuration.nix
    ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/backups.nix
    ../../lib/caddy.nix
    ../../lib/dns.nix
    ../../lib/dyndns.nix
    ../../lib/externalSmtp.nix
    ../../lib/fail2ban.nix
    # ../../lib/firefly-iii.nix
    ../../lib/generatedFiles.nix
    ../../lib/grafana.nix
    ../../lib/jupyter.nix
    ../../lib/home-assistant.nix
    # ../../lib/kea.nix
    ../../lib/locale.nix
    ../../lib/loki.nix
    ../../lib/mosquitto.nix
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
    ../../lib/vaultwarden.nix
    ../../lib/unbound.nix
    ../../lib/zfs.nix
  ];
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
  };
  automaticMaintenance = {
    enable = true;
    weeklyTime = "Sat 03:00:00";
    dailyTime = "02:30:00";
    randomizedDelay = "4h";
  };
  networking = {
    useDHCP = true;
    domain = "samgrayson.me";
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [ 7860 ];
    };
  };
  time = {
    timeZone = "America/Chicago";
  };
  locale = {
    unit_system = "us_customary";
    country = "US";
    lang = "en-US";
  };
  services = {
    paperless = {
      enable = false;
      passwordFile = secrets.paperless-password.path;
    };
    # dhcp-server = {
    #   enable = true;
    # };
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
    jupyter = {
      enable = true;
    };
    vaultwarden = {
      enable = true;
      admin_token_file = secrets.vaultwarden-admin-token.path;
    };
    home-assistant = {
      enable = true;
      secretsYaml = secrets.homeAssistantSecretsYaml.path;
      zigbee2mqttSecretsYaml = secrets.zigbee2mqttSecretsYaml.path;
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
    # kea = {
    #   ctrl-agent = {
    #     pass-file = secrets.keaCtrlAgentPass.path;
    #   };
    # };
    # firefly-iii = {
    #   appKeyFile = secrets.firefly-iii-app-key.path;
    #   database = {
    #     passwordFile = secrets.firefly-iii-postgres.path;
    #   };
    #   enable = true;
    # };
  };
  environment = {
    systemPackages = [ pkgs.speedtest-go pkgs.mtr ];
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
  users = {
    groups = {
      "smtp" = {};
    };
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
      homeAssistantSecretsYaml = {
        file = ../../secrets/home-assistant-secrets.yaml.age;
        owner = config.users.users.hass.name;
        group = config.users.users.hass.group;
      };
      # zigbee2mqttSecretsYaml = {
      #   file = ../../secrets/zigbee2mqttSecrets.yaml.age;
      #   owner = config.users.users.zigbee2mqtt.name;
      #   group = config.users.users.zigbee2mqtt.group;
      # };
      keaCtrlAgentPass = {
        file = ../../secrets/kea-ctrl-agent-pass.age;
      };
    } // {
      # firefly-iii-app-key = lib.mkIf config.services.firefly-iii.enable {
      #   file = ../../secrets/firefly-iii-app-key.age;
      #   mode = "0400";
      #   owner = config.services.firefly-iii.user;
      #   group = config.services.firefly-iii.group;
      # };
      # firefly-iii-postgres = lib.mkIf config.services.firefly-iii.enable {
      #   file = ../../secrets/firefly-iii-postgres.age;
      #   mode = "0400";
      #   owner = config.services.firefly-iii.user;
      #   group = config.services.firefly-iii.group;
      # };
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
