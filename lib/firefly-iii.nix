# https://github.com/timhae/firefly/pull/50#issuecomment-1894294212
# https://github.com/laravel/framework/issues/3987
# https://github.com/laravel/framework/issues/3987
# https://github.com/orgs/firefly-iii/discussions/8395
{ pkgs, lib, config, firefly, ... }: let
  cfg = config.services.firefly-iii;
  filterSrc = src:
    builtins.filterSource (path: type: type != "directory" || (baseNameOf path != ".git" && baseNameOf path != ".git" && baseNameOf path != ".svn")) src;
  firefly-iii = (pkgs.firefly-iii.overrideAttrs (old: {
    src = filterSrc ;
  })).override {
    dataDir = cfg.dataDir;
  };
  # shell script for local administration
  artisan = pkgs.writeScriptBin "firefly-iii" ''
    #! ${pkgs.runtimeShell}
    cd ${firefly-iii}
    sudo=exec
    if [[ "$USER" != ${cfg.user} ]]; then
      sudo='exec /run/wrappers/bin/sudo -u ${cfg.user}'
    fi
    $sudo ${cfg.phpPackage}/bin/php artisan $*
  '';
  firefly-config = {
    APP_URL = "https://${cfg.hostname}/";
    APP_KEY._secret = cfg.appKeyFile;

    DB_CONNECTION = "pgsql";
    DB_SOCKET = "/run/postgresql";
    DB_DATABASE = cfg.dbname;
    DB_USERNAME = cfg.user;

    MAIL_MAILER = "smtp";
    MAIL_HOST = config.externalSmtp.host;
    MAIL_PORT = config.externalSmtp.port;
    MAIL_FROM = config.externalSmtp.username;
    MAIL_USERNAME = lib.trivial.warn "TODO: implement smtp from firefly" config.externalSmtp.username;
    # MAIL_PASSWORD._secret = config.externalSmtp.passwordFile;
    MAIL_ENCRYPTION = if config.externalSmtp.security == "ssl" then "tls" else null;
  };
in {
  options = {
    services = {
      firefly-iii = {
        enable = lib.mkEnableOption "Firefly III";
        appKeyFile = lib.mkOption {
          description = "Path to secret app key file";
          type = lib.types.path;
        };
        hostname = lib.mkOption {
          description = "FQDN at which Firefly is accessible";
          type = lib.types.str;
          default = "firefly.${config.networking.domain}";
        };
        dataDir = lib.mkOption {
          description = "Firefly III data directory";
          default = "/var/lib/firefly-iii";
          type = lib.types.path;
        };
        user = lib.mkOption {
          description = "UNIX user for firefly";
          default = "firefly";
          type = lib.types.str;
        };
        group = lib.mkOption {
          description = "UNIX group for firefly";
          default = "firefly";
          type = lib.types.str;
        };
        phpPackage = lib.mkPackageOption pkgs "php" {};
        dbname = lib.mkOption {
          description = "Database name";
          default = "firefly";
          type = lib.types.str;
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs = lib.mkIf cfg.enable {
      overlays = [ firefly.overlays.default ];
    };
    services = {
      caddy = {
        virtualHosts = {
          "${cfg.hostname}" = {
            extraConfig = ''
              encode gzip zstd
              header Strict-Transport-Security max-age=15552000;
              try_files {path} {path}/ {path}/index.php?{query}
              root * ${firefly-iii}/public
              php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} { }
              file_server
            '';
          };
        };
      };
      postgresql = {
        enable = true;
        ensureDatabases = [ cfg.dbname ];
        ensureUsers = [ {
          name = cfg.user;
          # ensurePermissions = { "${cfg.database.name}" = "ALL PRIVILEGES"; };
        } ];
      };
      phpfpm = {
        pools = {
          firefly-iii = {
            user = cfg.user;
            group = cfg.group;
            phpPackage = cfg.phpPackage;
            phpOptions = ''
              log_errors = on
            '';
            settings = {
              "listen.mode" = "0660";
              "listen.owner" = cfg.user;
              "listen.group" = cfg.group;
            };
          };
        };
      };
    };
    systemd = {
      services = {
        firefly-iii-setup = {
          description = "Preparation tasks for Firefly III";
          before = [ "phpfpm-firefly-iii.service" ];
          after = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = cfg.user;
            WorkingDirectory = firefly-iii;
          };
          path = [ pkgs.replace-secret ];
          script =
            let
              isSecret = v: lib.isAttrs v && v ? _secret && (lib.isString v._secret || builtins.isPath v._secret);
              fireflyEnvVars = lib.generators.toKeyValue {
                mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
                  mkValueString = v: with builtins;
                    if isInt v then toString v
                    else if isString v then v
                    else if true == v then "true"
                    else if false == v then "false"
                    else if isSecret v then hashString "sha256" v._secret
                    else throw "unsupported type ${typeOf v}: ${(generators.toPretty {}) v}";
                };
              };
              secretPaths = lib.mapAttrsToList (_: v: v._secret) (lib.filterAttrs (_: isSecret) firefly-config);
              mkSecretReplacement = file: ''
                replace-secret ${lib.escapeShellArgs [ (builtins.hashString "sha256" file) file "${cfg.dataDir}/.env" ]}
              '';
              secretReplacements = lib.concatMapStrings mkSecretReplacement secretPaths;
              filteredConfig = lib.converge (lib.filterAttrsRecursive (_: v: ! lib.elem v [{ } null])) firefly-config;
              fireflyEnv = pkgs.writeText "firefly-iii.env" (fireflyEnvVars filteredConfig);
            in ''
              set -euo pipefail
              umask 077

              # create the .env file
              install -T -m 0600 -o ${cfg.user} ${fireflyEnv} "${cfg.dataDir}/.env"
              ${secretReplacements}
              if ! grep 'APP_KEY=base64:' "${cfg.dataDir}/.env" >/dev/null; then
                  sed -i 's/APP_KEY=/APP_KEY=base64:/' "${cfg.dataDir}/.env"
              fi

              # migrate db
              ${cfg.phpPackage}/bin/php artisan migrate --force
            '';
        };
      };
      tmpfiles.rules = [
        "d ${cfg.dataDir}                            0710 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage                    0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/app                0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/database           0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/export             0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/framework          0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/framework/cache    0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/framework/sessions 0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/framework/views    0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/logs               0700 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/storage/upload             0700 ${cfg.user} ${cfg.group} - -"
      ];
    };
    # User management
    users = {
      users = {
        ${cfg.user} = {
          group = cfg.group;
          isSystemUser = true;
        };
      };
      groups = {
        ${cfg.group} = { };
      };
    };
    environment = {
      systemPackages = [ artisan ];
    };
  };
}
