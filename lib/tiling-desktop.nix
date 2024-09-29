{ lib, pkgs, config, ... }:
{
  config = {
    environment = {
      systemPackages = with pkgs; [ swaylock ];
    };
    security = {
      pam = {
        services = {
          swaylock = {
            name = "swaylock";
          };
        };
      };
    };
    programs = {
      hyprland = {
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
        defaultSession = "hyprland";
      };
    };
  };
}
