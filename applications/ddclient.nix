{ pkgs, ... }:
{
  services = {
    ddclient = {
      enable = false;
      domains = [
        /* TODO */
      ];
      interval = "1min";
      quiet = true;
      protocol = "namecheap";
      ssl = true;
      web = "dynamicdns.park-your-domain.com/getip";
      username = "samgrayson.me";
      passwordFile = "/TODO";
    };
  };
}
