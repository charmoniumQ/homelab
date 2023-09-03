{ agenix, lib, ... }:
{
  imports = [
    agenix.nixosModules.default
  ];
  options = {
    hostKey = lib.mkOption {
      type = lib.types.str;
      description = "Used by Agenix; `cat /etc/ssh/ssh_host_*.pub` on a running NixOS system.";
    };
  };
}
