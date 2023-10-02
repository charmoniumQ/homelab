# https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki
# https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
# https://blog.roberthallam.org/2022/09/monitoring-zfs-latencies-in-proxmox-part-1/

{ lib, config, pkgs, ... }:
{
  config = {
    services = {
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      prometheus = {
        exporters = {
          node = {
            enable = config.services.prometheus.enable;
            port = lib.trivial.warn "Move this port number to a hash" 31681;
          };
          smartctl = {
            enable = config.services.prometheus.enable;
            port = lib.trivial.warn "Move this port number to a hash" 25738;
          };
          systemd = {
            enable = config.services.prometheus.enable;
            port = lib.trivial.warn "Move this port number to a hash" 56823;
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
    systemd = {
      services = {
        prometheus-journald-exporter = (
          let
            jctl-cfg = config.services.prometheus.exporters.journald-exporter;
            python = pkgs.python311.withPackages(ps: [ps.prometheus-client]);
            config-json = pkgs.writeText "prometheus-journald-exporter.json" (builtins.toJSON {
              port = jctl-cfg.port;
              frequencyMinutes = jctl-cfg.frequencyMinutes;
              units = builtins.mapAttrs
                (unit: unitConf: lib.attrsets.filterAttrs (unitConfOption: value: !builtins.isNull value) unitConf)
                jctl-cfg.units
              ;
            });
          in lib.attrsets.optionalAttrs jctl-cfg.enable {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              DynamicUser = true;
              Group = "systemd-journal";
              ExecStart = "${python}/bin/python -u ${./prometheus-journald-exporter.py} ${config-json}";
              LogsDirectory = "prometheus-journald-exporter";
            };
          }
        );
      };
    };
  };
  options = {
    services = {
      prometheus = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "IP address of prometheus instance";
        };
        exporters = {
          journald-exporter = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = config.services.prometheus.enable;
              description = "Whether to enable the journald-exporter";
            };
            frequencyMinutes = lib.mkOption {
              type = lib.types.int;
              default = 30;
              description = "Frequency to check jouranlctl for logs.";
            };
            port = lib.mkOption {
              type = lib.types.int;
              default = 32813;
              description = "Port on which the journald exporter will listen";
            };
            units = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  priority = lib.mkOption {
                    type = lib.types.nullOr (lib.types.enum [ "emerg" "alert" "crit" "err" "warning" "notice" "info" "debug" ]);
                    description = "Count all messages with a priority equal or more severe.";
                    default = null;
                   };
                  since = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "We will only count logs after this Systemd date/time";
                    default = null;
                   };
                  filters_regex = lib.mkOption {
                    type = lib.types.nullOr (lib.types.listOf lib.types.str);
                    description = "Ignore logs matching this regex";
                    default = null;
                  };
                  enable = lib.mkOption {
                    type = lib.types.nullOr lib.types.bool;
                    description = "Whether to log messages from this unit";
                    default = null;
                  };
                };
              });
              default = {
                "sshd.service" = {
                  filters_regex = [
                    "fatal: Timeout before authentication for "
                    "error: PAM: Authentication failure for "
                    "error: Protocol major versions differ: 2 vs\. 1"
                    "error: kex_exchange_identification: read: Connection reset by peer"
                    "error: kex_exchange_identification: Connection closed by remote host"
                    "error: kex_exchange_identification: banner line contains invalid characters"
                    "error: kex_exchange_identification: client sent invalid protocol identifier"
                  ];
                };
                "dbus.service" = {
                  filters_regex = [
                    "The maximum number of pending replies for"
                  ];
                };
                "redis-nextcloud.service" = {
                  filters_regex = [
                    "oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo"
                    "just started"
                    "Configuration loaded"
                    "Server initialized"
                    "User requested shutdown..."
                    "Redis is now ready to exit, bye bye..."
                  ];
                };
                "vaultwarden.service" = {
                  filters_regex = [
                    # This sometimes happens when the postgres server is starting up.
                    # If vaultwarden *truly* can't connect, it will cause the systemd service to fail,
                    # which we will see in a different alert.
                    "Can't connect to database, retrying: DieselCon."
                  ];
                };
                "system.slice" = {
                  enable = false;
                };
                "user-1000.slice" = {
                  enable = false;
                };
                "-.slice" = {
                  enable = false;
                };
                "init.scope" = {
                  enable = false;
                };
                default = {
                  since = "2023-09-30 05:00:00";
                };
              };
            };
          };
        };
      };
    };
  };
}
