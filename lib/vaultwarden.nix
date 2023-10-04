{ config, lib, ... }:
{
  config = let
    cfg = config.services.vaultwarden;
    smtpCfg = config.externalSmtp;
    dbName = "vaultwardendb";
  in {
    services = {
      vaultwarden = {
        dbBackend = "postgresql";
        # TODO: backup
        config = rec {
          # https://github.com/dani-garcia/vaultwarden/blob/1.29.2/.env.template
          SIGNUPS_ALLOWED = cfg.signups_allowed;
          DOMAIN = "https://${cfg.domain}";
          ROCKET_ADDRESS = cfg.address;
          ROCKET_PORT = cfg.port;
          ROCKET_LOG = "critical";
          USE_SYSLOG = true;
          LOG_LEVEL = cfg.log_level;

          # https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
          SMTP_HOST = smtpCfg.host;
          SMTP_PORT = smtpCfg.port;
          SMTP_SECURITY = if smtpCfg.security == "ssl" then "force_tls" else smtpCfg.security;
          SMTP_USERNAME = smtpCfg.username;
          SMTP_FROM = "${smtpCfg.fromUser}@${smtpCfg.fromDomain}";
          SMTP_FROM_NAME = DOMAIN;

          # DB
          DATABASE_URL = "postgresql://%2Frun%2Fpostgresql/${dbName}";
        };
        environmentFile = config.generatedFiles."vaultwarden.env".path;
      };
      postgresql = lib.attrsets.optionalAttrs (cfg.dbBackend == "postgresql") {
        enable = true;
        ensureDatabases = [ dbName ];
        ensureUsers = [
          {
            name = config.users.users.vaultwarden.name;
            ensurePermissions = {
              "DATABASE ${dbName}" = "ALL PRIVILEGES";
            };
          }
        ];
      };
    };
    reverseProxy = {
      domains = {
        "${cfg.domain}" = {
          port = cfg.port;
          extraProxyConfig = "header_up X-Real-IP {remote_host}";
        };
      };
    };
    generatedFiles = {
      "vaultwarden.env" = {
        name = "vaultwarden.env";
        script = ''echo -e "SMTP_PASSWORD=$(cat ${smtpCfg.passwordFile})\nADMIN_TOKEN=$(cat ${cfg.admin_token_file})"'';
        user = config.users.users.vaultwarden.name;
        group = config.users.groups.vaultwarden.name;
      };
    };
    backups = {
      volumes = {
        # https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
        vaultwarden = {
          filesystem = {
            paths = [ "/var/lib/bitwarden_rs/attachments" ];
          };
          postgresql = {
            databases = [ dbName];
          };
          services = [ "vaultwarden" ];
          keep_daily = 3;
          keep_monthly = 3;
          keep_yearly = 3;
        };
      };
    };
  };
  options = {
    services = {
      vaultwarden = {
        domain = lib.mkOption {
          type = lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]";
          description = ''
            The domain must match the address from where you access the server
            It's recommended to configure this value, otherwise certain functionality might not work,
            like attachment downloads, email links and U2F.
            For U2F to work, the server must use HTTPS, you can use Let's Encrypt for free certs
          '';
          default = "vaultwarden.${config.networking.domain}";
        };
        address = lib.mkOption {
          description = "Address on which we will listen for HTTP requests.";
          type = lib.types.str;
          default = "127.0.0.1";
        };
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port on which we will listen for HTTP requests.";
          default = lib.trivial.warn "Move this port number to a hash" 49912;
        };
        workers = lib.mkOption {
          type = lib.types.positive;
          description = "Number of Rocket workers";
          default = 4;
        };
        log_level = lib.mkOption {
          type = lib.types.enum ["trace" "debug" "info" "warn" "error" "off"];
          description = ''
            Change the verbosity of the log output
            Setting it to "trace" or "debug" would also show logs for mounted
            routes and static file, websocket and alive requests
          '';
          default = "warn";
        };
        signups_allowed = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Controls if new users can register";
        };
        signups_verify = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Controls if new users need to verify their email address upon registration
            Note that setting this option to true prevents logins until the email address has been verified!
            The welcome email will include a verification link, and login attempts will periodically
            trigger another verification email to be sent.
          '';
        };
        admin_token_file = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            File containing a token for the admin interface, preferably an Argon2 PCH string
            Vaultwarden has a built-in generator by calling `vaultwarden hash`
            For details see: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page#secure-the-admin_token
            If not set, the admin panel is disabled
          '';
        };
      };
    };
  };
}
