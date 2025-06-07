{ ... }: {
  services = {
    xserver = {
      desktopManager = {
        plasma5 = {
          bigscreen = {
            enable = true;
          };
        };
      };
    };
  };
}
