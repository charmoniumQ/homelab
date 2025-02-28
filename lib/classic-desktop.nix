{ pkgs, ... }: {
  environments = {
    packages = [
      pkgs.evtest-qt
      pkgs.evtest
      pkgs.wev
    ];
  };
  services = {
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
  };
  programs = {
    kdeconnect = {
      enable = true;
    };
  };
}
