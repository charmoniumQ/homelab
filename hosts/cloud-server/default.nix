{ config, lib, pkgs, disko, modulesPath, ... }:
let
  secrets = config.age.secrets;
in {
  imports = [
    disko.nixosModules.disko
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./hardware-configuration.nix
    ../../lib/actual.nix
    ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/backups.nix
    ../../lib/caddy.nix
    ../../lib/cli.nix
    ../../lib/dns.nix
    ../../lib/deployment.nix
    ../../lib/dyndns.nix
    ../../lib/externalSmtp.nix
    ../../lib/generatedFiles.nix
    ../../lib/fail2ban.nix
    ../../lib/firefly-iii.nix
    ../../lib/grafana.nix
    ../../lib/grocy.nix
    ../../lib/garage.nix
    ../../lib/jupyter.nix
    ../../lib/keycloak.nix
    ../../lib/locale.nix
    ../../lib/loki.nix
    ../../lib/matomo.nix
    ../../lib/matrix.nix
    ../../lib/mautrix/discord.nix
    ../../lib/mautrix/gmessages.nix
    ../../lib/mautrix/signal.nix
    ../../lib/mysql.nix
    ../../lib/networkedNode.nix
    ../../lib/nextcloud.nix
    ../../lib/nixConf.nix
    ../../lib/ntfy.nix
    ../../lib/runtimeTests.nix
    ../../lib/paperless.nix
    ../../lib/postgres.nix
    ../../lib/plausible.nix
    ../../lib/prometheus.nix
    ../../lib/promtail.nix
    ../../lib/reverseProxy.nix
    ../../lib/restricted-ssh-user.nix
    ../../lib/ssh.nix
    ../../lib/sysrq.nix
    ../../lib/sysadmin.nix
    ../../lib/sysadmin.nix
    ../../lib/vaultwarden.nix
  ];
  users = {
    users = {
      restricted-ssh-user = {
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5Ra/Ps/WkyBfU6u5UIo8qLGHzeNP09C6wWvraEhyMq"
            ] ++ config.sysadmin.sshKeys;
          };
        };
      };
    };
  };
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
    keycloak = {
      database = {
        passwordFile = config.age.secrets.keycloak-postgres.path;
      };
    };
    garage = {
      environmentFile = config.age.secrets.garage-env.path;
    };
    caddy = {
      enable = true;
      virtualHosts = {
        "home-assistant.samgrayson.me" = {
          extraConfig = ''
            reverse_proxy https://home-assistant2.samgrayson.me {
                header_up Host {upstream_hostport}
            }
          '';
        };
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
      package = pkgs.nextcloud31;
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
    plausible = {
      server = {
        secretKeybaseFile = config.age.secrets.plausible-secret-key.path;
      };
    };
    dyndns = {
      entries = [
        {
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          hosts = [
            "signal.mautrix"
            "discord.mautrix"
            "mautrix-gmessages"
            "ntfy"
            "cloud"
            "jupyter"
            "grafana"
            "nextcloud"
            "vaultwarden"
            "home-assistant"
            "matrix"
            "element"
            "mpd"
            "plausible"
            "matomo"
            "keycloak"
            "s3.garage"
            "*.s3.garage"
            "*.web.garage"
            "admin.garage"
            "budget"
          ] ++ lib.lists.optional config.services.firefly-iii.enable "firefly-iii";
          passwordFile = config.age.secrets.namecheapPassword.path;
        }
      ];
    };
    matrix-synapse = {
      extraConfigFiles = [
        config.age.secrets.synapse-registration.path
      ];
    };
    # firefly-iii = {
    #   enable = false;
    #   settings = {
    #     APP_KEY_FILE = config.age.secrets.firefly-iii-app-key.path;
    #     DB_PASSWORD_FILE = config.age.secrets.firefly-iii-postgres.path;
    #   };
    # };
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
      plausible-secret-key = {
        file  = ../../secrets/plausible-secret-key.age;
      };
      synapse-registration = {
        file = ../../secrets/synapse-registration.age;
        owner = "matrix-synapse";
        group = "matrix-synapse";
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
      keycloak-postgres = {
        file = ../../secrets/keycloak-postgres.age;
        owner = "keycloak";
        group = "keycloak";
      };
      garage-env = {
        file = ../../secrets/garage-env.age;
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
