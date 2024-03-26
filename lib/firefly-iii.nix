# https://github.com/timhae/firefly/pull/50#issuecomment-1894294212
# https://github.com/laravel/framework/issues/3987
# https://github.com/laravel/framework/issues/3987
# https://github.com/orgs/firefly-iii/discussions/8395
{ pkgs, lib, config, firefly, ... }: {
  imports = [ firefly.nixosModules.firefly-iii ];
  config = lib.mkIf config.services.firefly-iii.enable {
    nixpkgs = {
      overlays = [ firefly.overlays.default ];
    };
    # TODO: enable redis acceleration
    services = {
      firefly-iii = {
        appURL = "https://firefly-iii.${config.networking.domain}";
        hostname = "firefly-iii.${config.networking.domain}";
        # Note: username must be a valid postgres db name
        user = "firefly";
        group = "firefly";
        database = {
          type = "pgsql";
          host = "localhost";
          port = config.services.postgresql.port;
          socket = null;
          # db username must be UNIX username because we want to log in via UNIX socket
          user = config.services.firefly-iii.user;
          # db name must be same as db username because of ensureDBOwnership
          name = config.services.firefly-iii.user;
        };
        mail = {
          driver = "smtp";
          host = config.externalSmtp.host;
          port = config.externalSmtp.port;
          from = config.externalSmtp.username;
          user = config.externalSmtp.username;
          passwordFile = config.externalSmtp.passwordFile;
          encryption = if config.externalSmtp.security == "ssl" then "tls" else null;
        };
      };
      caddy = {
        virtualHosts = {
          "${config.services.firefly-iii.hostname}" = {
            extraConfig = ''
              encode gzip zstd
              header Strict-Transport-Security max-age=15552000;
              try_files {path} {path}/ {path}/index.php?{query}
              root * ${config.systemd.services.firefly-iii-setup.serviceConfig.WorkingDirectory}/public
              php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} { }
              file_server
            '';
          };
        };
      };
      postgresql = {
        enable = true;
        ensureDatabases = [ config.services.firefly-iii.database.name ];
        ensureUsers = [ {
          name = config.services.firefly-iii.database.user;
          ensureDBOwnership = true;
        } ];
      };
    };
    dns = {
      localDomains = [ "${config.services.firefly-iii.hostname}" ];
    };
    users = {
      users = {
        "${config.services.firefly-iii.user}" = {
          isSystemUser = true;
          group = "${config.services.firefly-iii.group}";
          extraGroups = [ "smtp" ];
        };
        "${config.services.caddy.user}".extraGroups = [ config.services.firefly-iii.group ];
      };
      groups = {
        "${config.services.firefly-iii.group}" = {};
      };
    };
  };
}
