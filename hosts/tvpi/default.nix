{ config, lib, pkgs, modulesPath, ... }:
let
  secrets = config.age.secrets;
in {
  # https://www.eisfunke.com/posts/2023/nixos-on-raspberry-pi.html
  imports = [
    ./hardware-configuration.nix
    ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/backups.nix
    ../../lib/caddy.nix
    ../../lib/desktop/generic.nix
    ../../lib/desktop/lxqt.nix
    ../../lib/dyndns.nix
    ../../lib/externalSmtp.nix
    ../../lib/locale.nix
    ../../lib/podman.nix
    # ../../lib/docker.nix
    ../../lib/fwupd.nix
    ../../lib/generatedFiles.nix
    ../../lib/home-assistant.nix
    ../../lib/kodi.nix
    ../../lib/networkedNode.nix
    ../../lib/nixConf.nix
    ../../lib/pia.nix
    ../../lib/reverseProxy.nix
    ../../lib/runtimeTests.nix
    ../../lib/sound.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
    "${toString modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

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

  sdImage = {
    imageBaseName = "tvpi";
    rootPartitionUUID = lib.lists.last (lib.strings.splitString "/" config.fileSystems."/".device);
    compressImage = false;
  };

  networking = {
    firewall = {
      enable = true;
    };
  };

  sysadmin = {
    username ="sam";
    hashedPassword = "$y$j9T$/YEWDGOkn3DQ5TVuylQMB.$ccqCLtZsTeKn3.aRBAXKqVLusBcvRcWOXIne.6d2AU5";
  };

  users = {
    users = {
      sam = {
        shell = pkgs.zsh;
      };
    };
  };

  programs = {
    zsh = {
      enable = true;
    };
  };

  automaticMaintenance = {
    enable = false;
  };

  boot = {
    binfmt = {
      # TODO: this
      #emulatedSystems = [ "aarch64-linux" "x86-64"];
    };
  };

  services = {
    caddy = {
      enable = true;
    };
    pia = {
      authUserPassFile = secrets.pia-auth-user-pass.path;
    };
    home-assistant = {
      enable = true;
      hostname = "home-assistant2.samgrayson.me";
      secretsYaml = config.age.secrets.homeAssistantSecretsYaml.path;
    };
    dyndns = {
      entries = [
        {
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          hosts = [ "home-assistant2" ];
          domain = "samgrayson.me";
          passwordFile = secrets.namecheapPassword.path;
        }
      ];
    };
  };

  # Suppress error when switching
  # https://discourse.nixos.org/t/nixos-rebuild-switch-upgrade-networkmanager-wait-online-service-failure/30746
  systemd = {
    services = {
      NetworkManager-wait-online = {
        serviceConfig = {
          ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
        };
      };
    };
  };

  backups = {
    enable = true;
    enableTimers = false;
    passwordFile = secrets.resticPassword.path;
    environmentFile = secrets.resticEnvironmentFile.path;
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
      pia-auth-user-pass = {
        file = ../../secrets/pia-auth-user-pass.age;
      };
    } // lib.attrsets.optionalAttrs config.services.home-assistant.enable {
      homeAssistantSecretsYaml = {
        file = ../../secrets/home-assistant-secrets.yaml.age;
        owner = config.users.users.hass.name;
        group = config.users.users.hass.group;
      };
    };
  };
}
