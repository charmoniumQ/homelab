{ ... }: {
  services = {
    displayManager = {
      sddm = {
        enable = true;
      };
    };
    xserver = {
      enable = true;
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
