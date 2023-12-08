{ lib, config, ... }:
{
  config = {
    security = {
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
    };
    services = {
      xserver = {
        enable = true;
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
          defaultSession = "hyprland";
        };
        # desktopManager = {
        #   lxqt = {
        #     enable = config.desktop.guiFramework == "qt";
        #   };
        #   lxde = {
        #     enable = config.desktop.guiFramework == "gtk";
        #   };
        # };
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
