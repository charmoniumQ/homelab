{ config, lib, pkgs, disko, benchexec-nixpkgs, ... }:

{
  imports = [
    disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko.nix
    # ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/desktop.nix
    ../../lib/classic-desktop.nix
    ../../lib/locale.nix
    ../../lib/podman.nix
    ../../lib/docker.nix
    ../../lib/fwupd.nix
    ../../lib/nixConf.nix
    ../../lib/pia.nix
    ../../lib/sound.nix
    ../../lib/swaylock.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
  ];

  networking = {
    firewall = {
      enable = true;
    };
  };

  sysadmin = {
    username ="sam";
    email = "sam@samgrayson.me";
    hashedPassword = "$y$j9T$Ix52oWTX.jUoRurwwxzj9.$VXXiZ6e25vypJMiGfBi1qnSC3ge8QYmzfcxcWWb5Rq1";
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
      emulatedSystems = [ "aarch64-linux" "x86-64"];
    };
  };

  services = {
    pia = {
      authUserPassFile = config.age.secrets.pia-auth-user-pass.path;
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
      pia-auth-user-pass = {
        file = ../../secrets/pia-auth-user-pass.age;
      };
    };
  };
}
