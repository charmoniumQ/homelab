{ lib, pkgs, config, ... }:
{
  config = {
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
