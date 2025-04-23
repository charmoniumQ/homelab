{ config, ... }:
rec {
  reverseProxy = {
    domains = {
      "budget.${config.networking.domain}" = {
        port = services.actual.settings.port;
      };
    };
  };
  services = {
    actual = {
      enable = true;
      settings = {
        port = 19243;
      };
    };
  };
}
