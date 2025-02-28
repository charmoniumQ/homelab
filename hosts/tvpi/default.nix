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
    ../../lib/deployment.nix
    ../../lib/dyndns.nix
    ../../lib/locale.nix
    ../../lib/fwupd.nix
    #../../lib/generatedFiles.nix
    ../../lib/networkedNode.nix
    ../../lib/nixConf.nix
    ../../lib/reverseProxy.nix
    ../../lib/runtimeTests.nix
    ../../lib/sound.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
    ../../lib/sysrq.nix
    "${toString modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  deployment = {
    hostName = "192.168.1.17";
    sudo = true;
    username ="sam";
  };

  environment = {
    systemPackages = [
      pkgs.libraspberrypi
    ];
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
      sam = { };
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

  age = {
    secrets = {
    };
  };
}
