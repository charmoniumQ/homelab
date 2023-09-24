{ lib, ... }:
{
  options = {
    automaticMaintenance = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable options which automatically update or maintain the filesystem. Note this may induce reboots.";
      };
      time = lib.mkOption {
        type = lib.types.str;
        description = "Time for automatic maintenance. See https://www.freedesktop.org/software/systemd/man/systemd.time.html";
      };
    };
  };
}
