{ lib, pkgs, config, ... }:
{
  config = {
    xdg = {
      portal = {
        enable = true;
      };
    };
    environment = {
      systemPackages = with pkgs; [ flatpak ];
    };
    fonts = {
      enableDefaultPackages = true;
    };
    security = {
      polkit = {
        enable = true;
      };
    };
    networking = {
      networkmanager = {
        enable = lib.mkDefault true;
      };
    };
    programs = {
      dconf = {
        enable = true;
      };
    };
    services = {
      flatpak = {
        enable = true;
      };
      udisks2 = {
        enable = true;
      };
      displayManager = {
        autoLogin = {
          enable = true;
          user = config.sysadmin.username;
        };
      };
    };
  };
}
