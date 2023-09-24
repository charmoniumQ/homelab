{ lib, config, ... }:
{
  services = {
    zfs = {
      autoScrub = {
        enable = config.automaticMaintenance.enable;
        interval = config.automaticMaintenance.time;
      };
      trim = {
        enable = config.automaticMaintenance.enable;
        interval = config.automaticMaintenance.time;
      };
      zed = {
        settings = {
          ZED_DEBUG_LOG = "/var/log/zed.debug.log";
        };
      };
    };
    prometheus = {
      exporters = {
        zfs = {
          enable = config.services.prometheus.enable;
          port = lib.trivial.warn "Move this port number to a hash" 49328;
        };
      };
    };
  };
}
