{ lib, pkgs, config, ...}: {
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
  } // lib.mkIf config.wifi {
    networking = {
      networkmanager = {
        enable = lib.mkDefault true;
      };
    };
  };
  options = {
    localIP = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}");
      description = "LAN IP address for local services.";
      default = null;
    };
    externalIP = lib.mkOption {
      type = lib.types.strMatching "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}";
      description = "LAN IP address for local services.";
    };
    wifi = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable WiFi";
    };
  };
}
