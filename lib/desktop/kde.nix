{ pkgs, ... }: {
  services = {
    desktopManager = {
      plasma6 = {
        enable = true;
        enableQt5Integration = false;
      };
    };
  };
  programs = {
    kdeconnect = {
      enable = true;
    };
  };
  environment = {
    plasma6 = {
      excludePackages = with pkgs.kdePackages; [
        # ark
        # konsole
        elisa
        # gwenview
        # okular
        # kate
        # dolphin
        # baloo-widgets
        # dolphin-plugins
      ];
    };
    systemPackages = with pkgs; [
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
      kdePackages.sddm-kcm
    ];
  };
  xdg = {
    portal = {
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
    };
  };
}
