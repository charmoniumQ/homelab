{ config, lib, pkgs, ... }:
let
  cfg = config.backups;
  jsonCfg = (pkgs.formats.json {}).generate "cfg.json" cfg;
  python_ = pkgs.python311;
  python = "${python_}/bin/python";
  script = pkgs.writeText "script.py" (builtins.readFile ./backups.py);
  resticBackups = builtins.mapAttrs (volume: volumeCfg: {
    initialize = true;
    backupPrepareCommand = "${python} ${jsonCfg} prepare ${volume}";
    backupCleanupCommand = "${python} ${jsonCfg} cleanup ${volume}";
    paths = (
      volumeCfg.filesystem.paths
      ++ (builtins.map
        (dbName: "/tmp/snapshots/${dbName}")
        volumeCfg.postgresql.databases)
    );
    environmentFile = config.backups.environmentFile;
    repository = cfg.localRepo;
    passwordFile = config.backups.passwordFile;
  }) config.backups.volumes;
in {
  config = {
    services = {
      restic = {
        backups = builtins.listToAttrs (
          (lib.attrsets.mapAttrsToList
            (name: cfg: {
              name = "${name}-remote";
              value = resticBackups."${name}" // {
                repository = config.backups.remoteRepo;
                timerConfig = {
                  OnCalendar = config.automaticMaintenance.weeklyTime;
                  RandomizedDelaySec = config.automaticMaintenance.randomizedDelay;
                };
                pruneOpts = [
                  "--keep-monthly ${builtins.toString cfg.keep_monthly}"
                  "--keep-yearly ${builtins.toString cfg.keep_yearly}"
                ];
              };
            })
            config.backups.volumes)
          ++ (lib.attrsets.mapAttrsToList
            (name: cfg: {
              name = "${name}-local";
              value = resticBackups."${name}" // {
                repository = config.backups.localRepo;
                timerConfig = {
                  OnCalendar = config.automaticMaintenance.dailyTime;
                  RandomizedDelaySec = config.automaticMaintenance.randomizedDelay;
                };
                pruneOpts = [
                  "--keep-daily ${builtins.toString cfg.keep_daily}"
                ];
              };
            })
            config.backups.volumes)
        );
      };
    };
  };
  options = {
    backups = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to enable periodic backups of databases and files";
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
      sudo = lib.mkOption {
        type = lib.types.package;
        description = "Package in which to find sudo";
        default = "${pkgs.sudo}";
      };
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package in which to find pg_dump";
        default = "${pkgs.postgresql}";
      };
      volumes = lib.mkOption {
        description = "Set of things to backup";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            postgresql = {
              databases = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Databases to backup";
                default = [ ];
              };
              url = lib.mkOption {
                type = lib.types.strMatching "postgres://[-a-zA-Z0-9@:%._\+~#=]{1,256}";
                description = "URL in which to find postgres databases";
                default = "postgres://%2Frun%2Fpostgresql";
              };
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
          };
        });
      };
    };
  };
}
