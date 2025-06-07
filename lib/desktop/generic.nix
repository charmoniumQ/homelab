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
        xdgOpenUsePortal = true;
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
      rtkit = {
        # Possibly, needed for pipewire to get rt priority
        # kde won't start without it
        enable = true;
      };
    };
    networking = {
      networkmanager = {
        enable = lib.mkDefault true;
      };
    };
    programs = {
      seahorse = {
        enable = true;
      };
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
          wayland = {
            enable = true;
          };
        };
        autoLogin = {
          enable = true;
          user = config.sysadmin.username;
        };
      };
      gnome = {
        gnome-keyring = {
          enable = true;
        };
      };
    };
  };
}
