{ pkgs, ... }: {
  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  services = {
    tlp = {
      enable = true;
      settings = {};
    };
  };
  environment.systemPackages = with pkgs; [
    tlp
    powertop
  ];
}
