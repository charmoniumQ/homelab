# https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki
# https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
# https://blog.roberthallam.org/2022/09/monitoring-zfs-latencies-in-proxmox-part-1/

{ lib, config, pkgs, ... }:
let
  cfg = config.services.prometheus;
in {
  config = {
    environment = {
      defaultPackages = [ pkgs.htop ];
    };
    services = {
      # https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
      prometheus = {
        listenAddress = "127.0.0.1";
        port = lib.trivial.warn "Move this port number to a hash" 26434;
        globalConfig = {
          scrape_interval = "1m";
        };
        exporters = {
          node = {
            enable = cfg.enable;
            port = lib.trivial.warn "Move this port number to a hash" 31681;
            listenAddress = "127.0.0.1";
          };
          smartctl = {
            enable = cfg.enable;
            port = lib.trivial.warn "Move this port number to a hash" 25738;
            listenAddress = "127.0.0.1";
          };
          systemd = {
            enable = cfg.enable;
            port = lib.trivial.warn "Move this port number to a hash" 56823;
            listenAddress = "127.0.0.1";
          };
          blackbox = {
            enable = cfg.enable;
            port = lib.trivial.warn "Move this port number to a hash" 18245;
            listenAddress = "127.0.0.1";
            configFile = (pkgs.formats.json {}).generate "config.json" {
              modules = {
                my_tcp = {
                  prober = "http";
                  timeout = "${builtins.toString cfg.exporters.blackbox-exporter.timeout}s";
                  http = {
                    valid_status_codes = [ 200 201 300 301 ];
                  };
                };
                my_icmp = {
                  prober = "icmp";
                  timeout = "${builtins.toString cfg.exporters.blackbox-exporter.timeout}s";
                  icmp = {
                    preferred_ip_protocol = "ip4";
                  };
                };
                my_udp = {
                  prober = "icmp";
                  timeout = "${builtins.toString cfg.exporters.blackbox-exporter.timeout}s";
                  icmp = {
                    preferred_ip_protocol = "udp";
                  };
                };
              };
            };
          };
        };
        scrapeConfigs = [ {
          job_name = "nodes";
          static_configs = [
            {
              targets =
                lib.attrsets.mapAttrsToList
                  (name: value: "localhost:${builtins.toString value.port}")
                  (lib.attrsets.filterAttrs
                    (name: value: name != "unifi-poller" && name != "blackbox" && name != "blackbox-exporter" && builtins.isAttrs value && value.enable)
                    cfg.exporters);
            }
          ];
        } ]
        ++ (builtins.map (proto: {
          scrape_interval = "${builtins.toString cfg.exporters.blackbox-exporter.interval}s";
          job_name = "isp_${proto}";
          metrics_path = "/probe";
          params = {
            module = [ "my_${proto}" ];
          };
          static_configs = [ {
            targets = cfg.exporters.blackbox-exporter.targetIPs;
          } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:18245";
            }
          ];
        }) [ "tcp" "udp" "icmp" ])
        ;
      };
    };
    systemd = {
      services = {
        prometheus-journald-exporter = (
          let
            jctl-cfg = cfg.exporters.journald-exporter;
            python = pkgs.python311.withPackages(ps: [ps.prometheus-client ps.retry]);
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
        exporters = {
          blackbox-exporter = {
            targetIPs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "1.1.1.1" "80.80.80.80" "142.250.190.78" ];
            };
            interval = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 60;
            };
            timeout = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 5;
            };
          };
          journald-exporter = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = cfg.enable;
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
                "caddy.service" = {
                  filters_regex = [
                    "Reload failed for Caddy."
                  ];
                };
                "sshd.service" = {
                  filters_regex = [
                    "fatal: Timeout before authentication for "
                    "error: PAM: Authentication failure for "
                    "error: Protocol major versions differ: 2 vs\. 1"
                    "error: kex_exchange_identification: read: Connection reset by peer"
                    "error: kex_exchange_identification: Connection closed by remote host"
                    "error: kex_exchange_identification: banner line contains invalid characters"
                    "error: kex_exchange_identification: client sent invalid protocol identifier"
                    "error: beginning MaxStartups throttling"
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
                "dhcpcd.service" = {
                  filters_regex = [
                    "DHCP lease expired"
                  ];
                };
                "init.scope" = {
                  enable = false;
                };
                default = {
                  since = "2023-10-19 00:00:00";
                };
              };
            };
          };
        };
      };
    };
  };
}
