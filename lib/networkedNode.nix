{ lib, ...}: {
  config = {
    networking = {
      firewall = {
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
