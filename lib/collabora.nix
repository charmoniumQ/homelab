{
  pkgs,
  lib,
  config,
  ...
}:
let
  hostname = "collabora.${config.networking.domain}";
  cfg = config.services.collabora-online;
in {
  services = {
    collabora-online = {
      enable = true;
    };
  };
  reverseProxy = {
    domains = {
      "collabora.${config.networking.domain}" = {
        inherit (cfg) port;
        host = "127.0.0.1";
      };
    };
  };
}
