{ lib, pkgs, config, ... }:
{
  config = {
    fonts = {
      packages = [
        pkgs.nerd-fonts.fira-code
        pkgs.fira
        pkgs.emacs-all-the-icons-fonts
      ];
    };
    xdg = {
      portal = {
        enable = true;
      };
    };
    environment = {
      systemPackages = with pkgs; [
        flatpak
      ];
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
      appimage = {
        enable = true;
      };
    };
    services = {
      atd = {
        enable = true;
      };
      flatpak = {
        enable = true;
      };
      udisks2 = {
        enable = true;
      };
      displayManager = {
        sddm = {
          enable = true;
        };
        autoLogin = {
          enable = true;
          user = config.sysadmin.username;
        };
      };
    };
  };
}
