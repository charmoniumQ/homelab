{ pkgs, ... }: {
  services = {
    dbus = {
      # Long ago, in the GNOME 2 era, applications used GConf service to store configuration.
      # This has been deprecated for many years
      # but some applications were abandoned before they managed to upgrade to a newer dconf system.
      # packages = with pkgs; [ gnome2.GConf ];
    };
    xserver = {
      enable = true;
      desktopManager = {
        gnome = {
          enable = true;
        };
      };
    };
    udev = {
      packages = with pkgs; [ gnome-settings-daemon ];
    };
  };
  environment = {
    systemPackages = with pkgs; [
      adwaita-icon-theme
      gnomeExtensions.appindicator
      gnome-tweaks
    ];
    gnome = {
      excludePackages = (with pkgs; [
        atomix # puzzle game
        #cheese # webcam tool
        epiphany # web browser
        #evince # document viewer
        geary # email reader
        #gedit # text editor
        gnome-characters
        gnome-contacts
        gnome-initial-setup
        gnome-music
        gnome-photos
        gnome-terminal
        gnome-tour
        hitori # sudoku game
        iagno # go game
        tali # poker game
        totem # music player
        yelp
      ]);
    };
  };
  programs = {
    dconf = {
      enable = true;
    };
  };
}
