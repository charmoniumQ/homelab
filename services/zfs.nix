{ lib, config, ... }:
{
  imports = [
    ../impl/prometheus.nix
  ];
  config = {
    services = {
      zfs = {
        autoScrub = {
          enable = config.endOptions.automaticMaintenance.enable;
          interval =
            lib.trivial.warn
              "See if this can take randomizedDelay"
              config.endOptions.automaticMaintenance.weeklyTime;
        };
        trim = {
          enable = config.endOptions.automaticMaintenance.enable;
          interval =
            lib.trivial.warn
              "See if this can take randomizedDelay"
              config.endOptions.automaticMaintenance.weeklyTime;
        };
        zed = {
          settings = {
            ZED_DEBUG_LOG = lib.trivial.warn "Do we need this?" /var/log/zed.debug.log;
          };
        };
      };
      prometheus = {
        exporters = {
          zfs = {
            enable = true;
            port = 54847; # ./string_to_port.py prometheus.exporters.zfs
          };
        };
      };
    };
  };
}
