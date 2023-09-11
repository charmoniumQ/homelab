{ config, lib, ... }:
{
  config = {
    services = {
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      grafana = {
        settings = {
          server = {
            # domain = config.services.grafana.hostname;
            # http_port = config.services.grafana._port;
            root_url = "https://${config.services.grafana.settings.server.domain}";
            # This gets reverseProxied from https://${domain} to http://127.0.0.1:${builtins.toString http_port}
            protocol = "http";
            http_addr = "127.0.0.1";
          };
        };
        provision = {
          datasources = {
            settings = {
              datasources =
                (lib.lists.optional
                  config.services.prometheus.enable
                  {
                    access = "proxy";
                    name = "Prometheus";
                    type = "prometheus";
                    url = "http://localhost:${toString config.services.prometheus.port}";
                  }
                ) ++ (lib.lists.optional
                  config.services.loki.enable
                  {
                    access = "proxy";
                    name = "Loki";
                    type = "loki";
                    url = "http://localhost:${toString config.services.loki.port}";
                  }
                );
            };
          };
          dashboards = {
            path = ./dashboards;
          };
          alerting = {
            rules = {
              path = ./alerting-rules.yaml;
            };
            contactPoints = {
              path = ./alerting-contact-points.json;
            };
          };
        };
      };
    };
    reverseProxy = {
      domains = {
        "${config.services.grafana.settings.server.domain}" = {
          internalOnly = true;
          port = config.services.grafana.settings.server.http_port;
        };
      };
    };
  };
}
