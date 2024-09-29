{ ... }: {
  services = {
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
    xserver = {
      enable = true;
    };
  };
  programs = {
    kdeconnect = {
      enable = true;
    };
  };
}
