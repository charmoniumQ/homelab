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
    ../../lib/deployment.nix
    ../../lib/desktop/generic.nix
    ../../lib/desktop/lxqt.nix
    ../../lib/deployment.nix
    ../../lib/dns.nix
    ../../lib/dyndns.nix
    ../../lib/externalSmtp.nix
    ../../lib/fail2ban.nix
    ../../lib/fwupd.nix
    ../../lib/generatedFiles.nix
    ../../lib/home-assistant.nix
    ../../lib/jellyfin.nix
    ../../lib/kodi.nix
    ../../lib/mpd.nix
    ../../lib/locale.nix
    ../../lib/mosquitto.nix
    ../../lib/networkedNode.nix
    ../../lib/nixConf.nix
    ../../lib/runtimeTests.nix
    ../../lib/reverseProxy.nix
    ../../lib/sound.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
    ../../lib/sysrq.nix
    ../../lib/zfs.nix
  ];
  deployment = {
    hostName = "192.168.1.28";
    sudo = true;
  };
  sysadmin = {
    hashedPassword = "$y$j9T$QfgpfZwUTsKsyhHUh71aD1$o9OuIHMYXkbUGOFbDaUOouJpnim9aRrX2YmQPYo.N67";
  };
  externalSmtp = {
    enable = true;
    tests = {
      enable = false;
    };
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
    useDHCP = lib.mkForce true;
    domain = "samgrayson.me";
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [ ];
    };
  };
  services = {
    nginx = {
      enable = false;
    };
    caddy = {
      enable = true;
    };
    home-assistant = {
      enable = true;
      hostname = "home-assistant2.${config.networking.domain}";
      secretsYaml = secrets.homeAssistantSecretsYaml.path;
      zigbee2mqttSecretsYaml = secrets.zigbee2mqttSecretsYaml.path;
    };
    dyndns = {
      entries = [
        {
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          hosts = [
            "home"
            "home-assistant2"
            "mpd2"
            "jellyfin2"
          ];
          passwordFile = secrets.namecheapPassword.path;
        }
      ];
    };
  };
  environment = {
    systemPackages = [
      pkgs.speedtest-go
      pkgs.mtr
    ];
  };
  backups = {
    enable = true;
    enableTimers = false;
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
      #   owner = con
      #   fig.users.users.zigbee2mqtt.name;
      #   group = config.users.users.zigbee2mqtt.group;
      # };
    };
  };
}
