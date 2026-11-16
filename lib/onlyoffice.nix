{
  pkgs,
  lib,
  config,
  ...
}:
let
  hostname = "onlyoffice.${config.networking.domain}";
  cfg = config.services.onlyoffice;
in {
  services = {
    onlyoffice = {
      enable = true;
      inherit hostname;
    };
  };
  reverseProxy = {
    domains = {
      "${cfg.hostname}" = {
        inherit (cfg) port;
        host = "127.0.0.1";
      };
    };
  };
}
