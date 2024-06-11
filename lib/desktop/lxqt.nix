{ ... }: {
  services = {
    xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
        };
      };
      desktopManager = {
        lxqt = {
          enable = true;
        };
      };
    };
  };
  programs = {
    kdeconnect = {
      enable = true;
    };
  };
}
