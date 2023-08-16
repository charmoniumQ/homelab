{ ... }:
{
  services = {
    loki = {
      enable = true;
    };
    grafana = {
      enable = true;
      domain = "grafana.local.samgrayson.me";
      port = 80;
      addr = "127.0.0.1";
    };
  };
};
