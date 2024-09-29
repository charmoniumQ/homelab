{ config, lib, pkgs, disko, nixos-hardware, benchexec-nixpkgs, ... }:
{
  imports = [
    disko.nixosModules.disko
    nixos-hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
    ./disko.nix
    ../../lib/agenix.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/desktop/generic.nix
    ../../lib/desktop/kde.nix
    ../../lib/desktop/hyprland.nix
    ../../lib/fprint.nix
    ../../lib/laptop.nix
    ../../lib/cli.nix
    ../../lib/locale.nix
    ../../lib/podman.nix
    ../../lib/docker.nix
    ../../lib/fwupd.nix
    ../../lib/nixConf.nix
    ../../lib/pia.nix
    ../../lib/printing.nix
    ../../lib/virtualbox.nix
    ../../lib/sound.nix
    ../../lib/desktop/swaylock.nix
    ../../lib/ssh.nix
    ../../lib/sysadmin.nix
    # ../../lib/tracing.nix # enable temporarily with `sudo sysctl -w kernel.perf_event_paranoid=1
  ];

  networking = {
    firewall = {
      enable = true;
    };
  };

  sysadmin = {
    username ="sam";
    email = "sam@samgrayson.me";
    hashedPassword = "$y$j9T$Ts4yey8oYBzEtUHuQh2F1.$n5LCsPQzaQ9YEsmOdHJtu3unhqPDHZHrAuAU.4ZzkY2";
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
    benchexec = {
      enable = true;
      users = [ "sam" ];
    };
  };

  automaticMaintenance = {
    enable = false;
  };

  boot = {
    binfmt = {
      emulatedSystems = ["aarch64-linux"];
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
