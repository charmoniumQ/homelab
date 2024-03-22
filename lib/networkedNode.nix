{ lib, pkgs, ...}: {
  config = {
    networking = {
      firewall = {
        enable = true;
      };
    };
    environment = {
      systemPackages = [ pkgs.tmux pkgs.rsync ];
    };
    programs = {
      mtr = {
        enable = true;
      };
    };
  };
  options = {
    localIP = lib.mkOption {
      type = lib.types.strMatching "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}";
      description = "LAN IP address for local services.";
    };
  };
}
