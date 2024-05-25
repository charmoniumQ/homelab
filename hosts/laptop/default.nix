{ config, lib, pkgs, disko, nixos-hardware, benchexec-nixpkgs, pia, ... }:

{
  imports = [
    disko.nixosModules.disko
    nixos-hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
    ./disko.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/benchexec.nix
    ../../lib/desktop.nix
    ../../lib/fprint.nix
    ../../lib/laptop.nix
    ../../lib/locale.nix
    ../../lib/podman.nix
    ../../lib/docker.nix
    ../../lib/nixConf.nix
    ../../lib/printing.nix
    ../../lib/virtualbox.nix
    ../../lib/sound.nix
    ../../lib/swaylock.nix
    ../../lib/sysadmin.nix
    # ../../lib/tracing.nix # enable temporarily with `sudo sysctl -w kernel.perf_event_paranoid=1
    pia.nixosModule
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
  time = {
    timeZone = "America/Chicago";
  };
  locale = {
    unit_system = "metric";
    country = "US";
    lang = "en-US";
  };
  automaticMaintenance = {
    enable = false;
  };
}
