# https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki
# https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
# https://blog.roberthallam.org/2022/09/monitoring-zfs-latencies-in-proxmox-part-1/

{ lib, config, ... }:
{
  config = {
    services = {
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      prometheus = rec {
        exporters = {
          node = {
            enable = true;
            port = 31681;
          };
          smartctl = {
            enable = true;
            port = 25738;
          };
          systemd = {
            enable = true;
            port = 56823;
          };
          zfs = {
            enable = true;
            port = 17418;
          };
        };
        scrapeConfigs = [{
          job_name = "nodes";
          static_configs = [ {
            targets =
              lib.attrsets.mapAttrsToList
                (name: value: "localhost:${toString value.port}")
                exporters;
          } ];
        }];
      };
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      # promtail = {
      #   enable = true;
      #   configuration = {
      #     server = {
      #       http_listen_port = 3031;
      #       grpc_listen_port = 0;
      #     };
      #     clients = [ {
      #       url = "http://${config.lokiIP}:${builtins.toString config.lokiPort}/loki/api/v1/push";
      #     } ];
      #     positions = {
      #       filename = "/tmp/positions.yaml";
      #     };
      #     scrape_configs = [ {
      #       job_name = "journal";
      #       journal = {
      #         json = false;
      #         labels = {
      #           job = "systemd-journal";
      #         };
      #         max_age = "12h";
      #       };
      #       relabel_configs = [
      #         # https://www.reddit.com/r/grafana/comments/v6t81i/loki_and_promtail_settings_you_recommend_for/ic2ywcp/
      #         {
      #           source_labels = [ "__journal__systemd_unit" ];
      #           target_label = "systemd_unit";
      #         }
      #         {
      #           source_labels = [ "__journal__hostname" ];
      #           target_label = "nodename";
      #         }
      #         {
      #           source_labels = [ "__journal_syslog_identifier" ];
      #           target_label = "syslog_identifier";
      #         }
      #       ];
      #     } ];
      #   };
      # };
    };
  };
  options = {
    prometheusIP = lib.mkOption {
      type = lib.types.str;
    };
    prometheusPort = lib.mkOption {
      type = lib.types.int;
      default = 3100;
    };
    # lokiIP = lib.mkOption {
    #   type = lib.types.str;
    # };
    # lokiPort = lib.mkOption {
    #   type = lib.types.int;
    #   default = 3473;
    # };
  };
}
