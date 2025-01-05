{ config, lib, pkgs, ... }:
/*
 * Manually trigger a backup like so: sudo systemctl restart restic-backups-${name}-(remote|local)
 * Manually restore a backup like so:
 *
 *     sudo systemctl stop ${name} # or equivalent
 *     sudo systemctl stop postgres # if necessary
 *     sudo restic-${name}-(remote|local) snapshots
 *     # select snapshot
 *     sudo restic-${name}-(remote|local) restore $snapshot --target /
 *     sudo -u postgres pg_restore --verbose --clean --dbname nextcloud /tmp/snapshots/nextcloud # if necessary
 */
let
  jsonCfg = (pkgs.formats.json {}).generate "cfg.json" ({
    paas = {
      backups = config.paas.backups;
      sql = config.paas.sql;
    };
    pkgs = { inherit (pkgs) postgres sudo; };
  });
  python = "${pkgs.python311}/bin/python";
  script = pkgs.writeText "script.py" (builtins.readFile ./backups/main.py);
  resticBackups = builtins.mapAttrs (volume: volumeCfg: {
    initialize = true;
    backupPrepareCommand = "${python} ${script} ${jsonCfg} prepare ${volume}";
    backupCleanupCommand = "${python} ${script} ${jsonCfg} cleanup ${volume}";
    paths = (
      volumeCfg.filesystem.paths
      ++ (builtins.map
        (dbName: "/tmp/snapshots/${dbName}")
        volumeCfg.sql.databases)
    );
    environmentFile = config.endOptions.backups.environmentFile;
    passwordFile = config.endOptions.backups.passwordFile;
    extraOptions = [ "--verbose" ];
  }) config.paas.backups.volumes;
in {
  config = {
    assertions = [ {
      assertion = config.paas.sql.provider == "postgres";
    } ];
    services = {
      prometheus = {
        exporters = {
          restic = {
            enable = config.services.prometheus.enable;
            port = 37098;
            environmentFile = config.endOptions.backups.environmentFile;
            passwordFile = config.endOptions.backups.passwordFile;
            repository = config.endOptions.backups.remoteRepo;
          };
        };
      };
      restic = {
        backups = builtins.listToAttrs (
          (lib.attrsets.mapAttrsToList
            (name: cfg: {
              name = "${name}-remote";
              value = resticBackups."${name}" // {
                repository = config.backups.remoteRepo;
                timerConfig = if config.backups.enableTimers then {
                  OnCalendar = config.automaticMaintenance.weeklyTime;
                  RandomizedDelaySec = config.automaticMaintenance.randomizedDelay;
                } else null;
                pruneOpts = [
                  "--keep-monthly ${builtins.toString cfg.keep_monthly}"
                  "--keep-yearly ${builtins.toString cfg.keep_yearly}"
                ];
              };
            })
            config.paas.backups.volumes)
          ++ (lib.attrsets.mapAttrsToList
            (name: cfg: {
              name = "${name}-local";
              value = resticBackups."${name}" // {
                repository = config.backups.localRepo;
                timerConfig = if config.backups.enableTimers then {
                  OnCalendar = config.automaticMaintenance.dailyTime;
                  RandomizedDelaySec = config.automaticMaintenance.randomizedDelay;
                } else null;
                pruneOpts = [
                  "--keep-daily ${builtins.toString cfg.keep_daily}"
                ];
              };
            })
            config.paas.backups.volumes)
        );
      };
    };
  };
  options = {
    endOptions = {
      backups = {
        enableTimers = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to enable periodic backups (otherwise they must be manually invoked)";
        };
        keep_daily = lib.mkOption {
          description = "How many daily backups to keep";
          type = lib.types.ints.unsigned;
        };
        keep_monthly = lib.mkOption {
          description = "How many monthly backups to keep";
          type = lib.types.ints.unsigned;
        };
        keep_yearly = lib.mkOption {
          description = "How many yearly backups to keep";
          type = lib.types.ints.unsigned;
        };
        environmentFile = lib.mkOption {
          type = lib.types.path;
          description = "/path/to/file containing a systemd.exec-compatible environment file in which to run Restic; this will include Backblaze API keys, for example";
        };
        passwordFile = lib.mkOption {
          type = lib.types.path;
          description = "/path/to/file containing a secret password";
        };
        localRepo = lib.mkOption {
          type = lib.types.str;
          description = "Location of local repository for daily backups";
          default = "/var/lib/backups";
        };
        remoteRepo = lib.mkOption {
          type = lib.types.str;
          description = "Location of local repository for weekly and yearly backups";
          default = "/var/lib/remote-backups";
        };
      };
    };
    paas = {
      backups = {
        volumes = lib.mkOption {
          description = "Set of things to backup";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              databases = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Databases to backup";
                default = [ ];
              };
              filesystem = {
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.path;
                  description = "Directories to back up";
                };
              };
              enterMaintenanceMode = lib.mkOption {
                description = "Commands needed to enter maintenance mode for backups";
                default = "";
                type = lib.types.lines;
              };
              exitMaintenanceMode = lib.mkOption {
                description = "Commands needed to exit maintenance mode for backups";
                default = "";
                type = lib.types.lines;
              };
              services = lib.mkOption {
                description = "Services to stop/start while making backups";
                default = [ ];
                type = lib.types.listOf lib.types.str;
              };
            };
          });
        };
      };
    };
  };
}
