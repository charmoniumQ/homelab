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
      displayManager = {
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
        };
      };
      displayManager = {
        defaultSession = "hyprland";
      };
    };
  };
}
