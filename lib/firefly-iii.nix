{
  pkgs,
  lib,
  config,
  ...
}:
let
  hostname = "firefly-iii.${config.networking.domain}";

  cfg = config.services.firefly-iii;

in {
  services = {
    firefly-iii = {
      enableNginx = false;
      user = "firefly";
      group = "firefly";
      # TODO: enable redis acceleration
      settings = {
        APP_ENV = "local";
        # APP_KEY_FILE set by client
        APP_URL = "https://${hostname}";
        DB_CONNECTION = "pgsql";
        DB_HOST = "localhost";
        DB_PORT = config.services.postgresql.settings.port;
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
    caddy = lib.attrsets.optionalAttrs cfg.enable {
      virtualHosts = {
        "${hostname}" = {
          extraConfig = ''
              encode gzip zstd
              root * ${cfg.package}/public
              php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} { }
              file_server
            '';
        };
      };
    };
    postgresql = lib.attrsets.optionalAttrs cfg.enable {
      enable = true;
      ensureDatabases = [ cfg.settings.DB_DATABASE ];
      ensureUsers = [ {
        name = cfg.settings.DB_USERNAME;
        ensureDBOwnership = true;
      } ];
    };
  };
  dns = lib.attrsets.optionalAttrs cfg.enable {
    localDomains = [ hostname ];
  };
  users = lib.attrsets.optionalAttrs cfg.enable {
    users = {
      "${cfg.user}" = {
        isSystemUser = true;
        group = cfg.group;
        extraGroups = [ "smtp" ];
      };
      "${config.services.caddy.user}" = {
        extraGroups = [ cfg.group ];
      };
    };
    groups = {
      "${cfg.group}" = {};
    };
  };
}
