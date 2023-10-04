{ config, lib, pkgs, ... }:
let
  cfg = config.backups;
  pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
  postgres_url = "postgres://%2Frun%2Fpostgresql";
  sudo = "${pkgs.sudo}/bin/sudo";
  resticBackups = builtins.mapAttrs (name: cfg: {
    initialize = true;
    backupPrepareCommand = builtins.concatStringsSep "\n" (
      [
        "set -ex"
        "rm --recursive --force /tmp/snapshots"
        "mkdir --parents /var/lib/backups"
        cfg.enterMaintenanceMode
      ]
      ++ (builtins.map
        (service: "systemctl stop ${service}")
        cfg.services)
      ++ (builtins.map
        (dbName: ''
          mkdir --parents /tmp/snapshots/${dbName}
          chown postgres /tmp/snapshots /tmp/snapshots/${dbName}
          ${sudo} -u postgres ${pg_dump} --format=directory --file=/tmp/snapshots/${dbName}  ${postgres_url}/${dbName}
          chown root /tmp/snapshots /tmp/snapshots/${dbName}
        '')
        cfg.postgresql.databases)
    );
    backupCleanupCommand = builtins.concatStringsSep "\n" (
      [
        "set -ex"
        "rm --recursive --force /tmp/snapshots"
        cfg.exitMaintenanceMode
      ]
      ++ (builtins.map
        (service: "systemctl start ${service}\n")
        cfg.services)
    );
    paths = (
      cfg.filesystem.paths
      ++ (builtins.map
        (dbName: "/tmp/snapshots/${dbName}")
        cfg.postgresql.databases)
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
