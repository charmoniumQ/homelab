{ lib, config, ... }:
{
  config = {
    services = {
      #https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      promtail = {
        configuration = {
          server = {
            http_listen_port = 31924;
            grpc_listen_port = 0;
          };
          clients = [ {
            url = "http://${config.lokiIP}:${builtins.toString config.lokiPort}/loki/api/v1/push";
          } ];
          positions = {
            filename = "/tmp/positions.yaml";
          };
          scrape_configs = [ {
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
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "systemd_unit";
              }
              {
                source_labels = [ "__journal__hostname" ];
                target_label = "nodename";
              }
              {
                source_labels = [ "__journal_syslog_identifier" ];
                target_label = "syslog_identifier";
              }
            ];
          } ];
        };
      };
    };
  };
}
