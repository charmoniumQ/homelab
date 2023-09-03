{ lib, ...}: {
  options = {
    localIP = lib.mkOption {
      type = lib.types.str;
      description = "Expected IP of this machine on the LAN.";
    };
  };
}
