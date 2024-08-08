{
  pkgs,
  lib,
  config,
  ...
}:
let
  hostname = "firefly-iii.${config.networking.domain}";
in {
  services = {
    firefly-iii = {
      enableNginx = false;
      user = "firefly";
      group = "firefly";
      # TODO: enable redis acceleration
      settings = {
        APP_ENV = "local";
        APP_URL = "https://${hostname}";
        DB_CONNECTION = "pgsql";
        DB_HOST = "localhost";
        DB_PORT = config.services.postgresql.port;
        # db username must be UNIX username because we want to log in via UNIX socket in the future
        DB_USERNAME = config.services.firefly-iii.user;
        # db name must be same as db username because of ensureDBOwnership
        DB_DATABASE = config.services.firefly-iii.user;
        MAIL_MAILER = "smtp";
        MAIL_HOST = config.externalSmtp.host;
        MAIL_PORT = config.externalSmtp.port;
        MAIL_FROM = config.externalSmtp.username;
        MAIL_USERNAME = config.externalSmtp.username;
        MAIL_PASSWORD = lib.trivial.warn "Fix this so it actually works" "";
        MAIL_ENCRYPTION = if config.externalSmtp.security == "ssl" then "tls" else null;
      };
    };
    caddy = {
      virtualHosts = {
        "${hostname}" = {
          extraConfig = ''
              encode gzip zstd
              header Strict-Transport-Security max-age=15552000;
              try_files {path} {path}/ {path}/index.php?{query}
              root * ${config.services.firefly-iii.package}/public
              php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} { }
              file_server
            '';
        };
      };
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ config.services.firefly-iii.settings.DB_DATABASE ];
      ensureUsers = [ {
        name = config.services.firefly-iii.settings.DB_USERNAME;
        ensureDBOwnership = true;
      } ];
    };
  };
  dns = {
    localDomains = [ hostname ];
  };
  users = {
    users = {
      "${config.services.firefly-iii.user}" = {
        isSystemUser = true;
        group = config.services.firefly-iii.group;
        extraGroups = [ "smtp" ];
      };
      "${config.services.caddy.user}" = {
        extraGroups = [ config.services.firefly-iii.group ];
      };
    };
    groups = {
      "${config.services.firefly-iii.group}" = {};
    };
  };
}
