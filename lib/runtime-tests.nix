{ config, pkgs, lib, ... }:
{
  config = {
    systemd = {
      services = builtins.mapAttrs
        (name: value: {
          "runtime-test-${lib.strings.toLower name}" = {
            wantedBy = [ "multi-user.target" ];
            after = value.after;
            script = value.script;
            serviceConfig = {
              Type = "oneshot";
              User = value.user;
            };
          };
        })
        config.runtimeTests.tests
      ;
      timers = builtins.mapAttrs 
        (name: value: {
          "runtime-test-${lib.strings.toLower name}" = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              Unit = "runtime-test-${lib.strings.toLower name}";
              Persistent = true;
              OnCalendar = if builtins.isNull value.date then config.runtimeTests.defaultDate else value.date;
              AccuracySec = if builtins.isNull value.accuracySec then config.runtimeTests.defaultAccuracySec else value.accuracySec;
            };
          };
        })
        config.runtimeTests.tests
      ;
    };
  };
  options = {
    runtimeTests = {
      tests = lib.mkOption {
        description = "Run these tests after deployment and periodically while the server is running.";
        default = {};
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            script = lib.mkOption {
              type = lib.types.str;
              description = "Script to run. Exit code 0 indicates the test passes.";
            };
            after = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Systemd units to run this test after.";
              default = [ ];
            };
            user = lib.mkOption {
              type = lib.types.str;
              description = "User under which to run the test.";
              default = "root";
            };
            date = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "If not null, when to run the tests; otherwise use runtimeTests.defaultDate. See <https://www.freedesktop.org/software/systemd/man/systemd.time.html>";
            };
            accuracySec = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "If not null, allows Systemd to coalesce this event with nearby events at most $accuracySec away; otherwise use runtimeTests.defaultAccuracySec. <https://www.freedesktop.org/software/systemd/man/systemd.timer.html#AccuracySec=>";
            };
          };
        });
      };
      defaultDate = lib.mkOption {
        type = lib.types.str;
        description = "Systemd date, when to run the tests. See <https://www.freedesktop.org/software/systemd/man/systemd.time.html>";
        default = "hourly";
      };
      defaultAccuracySec = lib.mkOption {
        type = lib.types.str;
        description = "Allows Systemd to coalesce this event with nearby events at most $accuracySec away. <https://www.freedesktop.org/software/systemd/man/systemd.timer.html#AccuracySec=>";
        default = "30m";
      };
    };
  };
}
