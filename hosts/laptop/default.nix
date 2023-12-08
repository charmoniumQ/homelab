{ config, lib, pkgs, disko, nixos-hardware, ... }:

{
  imports = [
    disko.nixosModules.disko
    nixos-hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
    ./disko.nix
    ../../lib/automaticMaintenance.nix
    ../../lib/desktop.nix
    ../../lib/fprint.nix
    ../../lib/locale.nix
    ../../lib/nixConf.nix
    ../../lib/printing.nix
    ../../lib/sound.nix
    ../../lib/sysadmin.nix
  ];
  networking = {
    firewall = {
    enable = false;
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
