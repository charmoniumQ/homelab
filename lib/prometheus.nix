# https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki
# https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
# https://blog.roberthallam.org/2022/09/monitoring-zfs-latencies-in-proxmox-part-1/

{ lib, config, ... }:
{
  config = {
    services = {
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      prometheus = {
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
        };
        scrapeConfigs = [{
          job_name = "nodes";
          static_configs = [ {
            targets =
              lib.attrsets.mapAttrsToList
                (name: value: "localhost:${builtins.toString value.port}")
                (lib.attrsets.filterAttrs
                  (name: value: name != "unifi-poller" && builtins.isAttrs value && value.enable)
                  config.services.prometheus.exporters);
          } ];
        }];
      };
    };
  };
  options = {
    prometheus = {
      ip = lib.mkOption {
        type = lib.types.str;
        description = "IP address of prometheus instance";
      };
    };
  };
}
