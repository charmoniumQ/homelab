/*
Permits SSH access.
*/
{ ... }:
{
  services = {
    openssh = {
      enable = true;
    };
  };
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
    };
  };
}
