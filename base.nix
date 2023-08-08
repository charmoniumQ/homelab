/*
This file has "base" OS services and settings that are not host-specific, network-specific, or application-specific, but applications may depend on this.
E.g., SSH, log monitoring, ZFS, boot params, ...
*/

{ config, pkgs, lib, ... }:
{
  config = {
    system = {
      stateVersion = "23.11";
      autoUpgrade = {
        enable = true;
        allowReboot = true;
        dates = "daily";
        channel = "https://channels.nixos.org/nixos-23.11";
      };
      # TODO: enable
      # usbguard = {
      #   enable = true;
      # };
    };
    nix = {
      enable = true;
      package = pkgs.nixUnstable;
      channel = {
        enable = true;
      };
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
      };
      optimise = {
        automatic = true;
        dates = [
          "weekly"
        ];
      };
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    services = {
      openssh = {
        enable = true;
      };
    };
    users = {
      mutableUsers = false;
      users = {
        sysadmin = {
          isNormalUser = true;
          createHome = true;
          extraGroups = [ "wheel" ];
          openssh = {
            authorizedKeys = {
              keys = config.sysadmin.sshKeys;
            };
          };
        };
      };
    };
  };
  options = {
    sysadmin = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for alerts and ACME.";
      };
      sshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "SSH public key used for administrative access.";
      };
    };
  };
}
