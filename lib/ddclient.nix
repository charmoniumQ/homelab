{ lib, config, ... }:
{
  options = {
    dyndns = {
      provider = lib.mkOption {
        type = lib.types.str;
        description = "Dynamic DNS provider";
      };
      username = lib.mkOption {
        type = lib.types.str;
      };
      passwordFile = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  config = {
    services = {
      ddclient = {
        enable = false;
        domains = [
          "*.${config.networking.domain}"
        ];
        interval = "1min";
        quiet = true;
        protocol = config.dynns.provider;
        ssl = true;
        web = "dynamicdns.park-your-domain.com/getip";
        username = config.dyndns.username;
        passwordFile = config.dyndns.passwordFile;
      };
    };
  };
}
