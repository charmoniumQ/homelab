{ ... }:
{
  services = {
    # https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki
    # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
    promtail = {
      enable = true;
      configuration = {
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              json = false;
              labels = {
                job = "systemd-journal";
              };
              max_age = "12h";
            };
            relabel_configs = [
              # https://www.reddit.com/r/grafana/comments/v6t81i/loki_and_promtail_settings_you_recommend_for/ic2ywcp/
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "systemd_unit";
              }
            ];
          }
        ];
      };
    };
    prometheus = {
      enable = true;
      /*
      alertmanager = {
        enable = true;
        webExternalUrl = "alertmanager.samgrayson.me";
        # TODO: proxy ${services.prometheus.alertmanager.webExternalUrl} to localhost:${services.prometheus.alertmanager.port}
        # Also acquire ACME cert
      };
      */
      exporters = {
        node = {
          enable = true;
        };
        smartctl = {
          enable = true;
        };
        systemd = {
          enable = true;
        };
        zfs = {
          enable = true;
        };
      };
    };
  };
}
