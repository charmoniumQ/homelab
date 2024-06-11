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
      xserver = {
        enable = true;
        displayManager = {
          sddm = {
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
