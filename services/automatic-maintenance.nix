{ lib, ... }:
{
  options = {
    endOptions = {
      automaticMaintenance = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to enable automatic maintenance across multiple services";
        };
        dailyTime = lib.mkOption {
          type = lib.types.str;
          description = "Every-few-days time window for automatic maintenance. See https://www.freedesktop.org/software/systemd/man/systemd.time.html";
        };
        weeklyTime = lib.mkOption {
          type = lib.types.str;
          description = "Weekly or monthly automatic maintenance. See https://www.freedesktop.org/software/systemd/man/systemd.time.html";
        };
        randomizedDelay = lib.mkOption {
          type = lib.types.str;
          description = "Randomized delay for automatic maintenance. See https://www.freedesktop.org/software/systemd/man/systemd.time.html";
        };
      };
    };
  };
}
