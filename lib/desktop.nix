{ lib, pkgs, config, ... }:
{
  config = {
    environment = {
      systemPackages = with pkgs; [ flatpak swaylock ];
    };
    fonts = {
      enableDefaultPackages = true;
    };
    security = {
      pam = {
        services = {
          swaylock = {
            name = "swaylock";
          };
        };
      };
      polkit = {
        enable = true;
      };
    };
    networking = {
      networkmanager = {
        enable = true;
      };
    };
    programs = {
      hyprland = {
        enable = true;
      };
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
      xserver = {
        enable = true;
        displayManager = {
          lightdm = {
            enable = true;
          };
          # sddm = {
          #   enable = true;
          #   wayland = {
          #     enable = true;
          #   };
          # };
          autoLogin = {
            enable = true;
            user = config.sysadmin.username;
          };
          defaultSession = "hyprland";
        };
        desktopManager = {
          # lxqt = {
          #   enable = config.desktop.guiFramework == "qt";
          # };
          # lxde = {
          #   enable = config.desktop.guiFramework == "gtk";
          # };
        };
      };
    };
  };
  options = {
    desktop = {
      guiFramework = lib.mkOption {
        type = lib.types.enum [ "qt" "gtk" ];
	      default = "gtk";
      };
    };
  };
}
