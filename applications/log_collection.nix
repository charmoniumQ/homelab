{ ... }:
{
  services = {
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
      webExternalUrl = "prometheus.samgrayson.me";
      # TODO: proxy ${services.prometheus.webExternalUrl} to localhost:${services.prometheus.port}
      # Also acquire ACME cert
      /*
alert: Error
expr: 

alert: ManyWarnings
annotations:
  description:
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
