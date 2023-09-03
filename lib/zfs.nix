{
  services = {
    zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim = {
        enable = true;
        interval = "weekly";
      };
    };
    zed = {
      settings = {
        ZED_DEBUG_LOG = "/var/log/zed.debug.log";
      };
    };
    prometheus = {
      exporters = {
        zfs = {
          enable = true;
          port = 9428;
        };
      };
    };
  };
}
