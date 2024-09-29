{ pkgs, ... }: {
  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  services = {
    #tlp = {
    #  enable = true;
    #  settings = {};
    #};
    logind = {
      lidSwitch = "suspend";
      powerKey = "hibernate";
    };
  };
  environment.systemPackages = with pkgs; [
    tlp
    powertop
  ];
}
