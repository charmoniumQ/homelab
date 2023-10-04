{ lib, config, ... }:
{
  services = {
    zfs = {
      autoScrub = {
        enable = config.automaticMaintenance.enable;
        interval =
          lib.trivial.warn
            "See if this can take randomizedDelay"
            config.automaticMaintenance.weeklyTime;
      };
      trim = {
        enable = config.automaticMaintenance.enable;
        interval =
          lib.trivial.warn
            "See if this can take randomizedDelay"
            config.automaticMaintenance.weeklyTime;
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
