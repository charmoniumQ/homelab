{ pkgs, config, lib, ... }:
let
  cfg = config.services.home-assistant;
  userName = "hass";
  dbName = "hass";
in {
  config = {
    environment = {
      systemPackages = [ cfg.package ];
    };
    services = {
      home-assistant = {
        enable = true;
        config = {
          default_config = {};
          homeassistant = {
            name = "Home";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            elevation = "!secret elevation";
            unit_system =
              if config.locale.unit_system == "us_customary" then "imperial" else config.locale.unit_system;
            time_zone = config.time.timeZone;
            currency = config.locale.currency;
            external_url = "https://${cfg.hostname}";
            internal_url = "https://${cfg.hostname}";
          };
          calendar = []
            ++ (lib.lists.optional config.services.nextcloud.enable {
              platform = "caldav";
              username = "!secret nextcloud_username";
              password = "!secret nextcloud_password";
              url = "https://${config.services.nextcloud.hostName}/remote.php/dav";
            })
          ;
          recorder = {
            db_url = "postgresql://${userName}@/${dbName}?host=/run/postgresql";
          };
          lovelace = {
            # mode = "yaml";
            mode = "storage";
          };
          http = {
            server_host = "127.0.0.1";
            server_port = cfg.http_port;
            use_x_forwarded_for = true;
            trusted_proxies = [ "127.0.0.1" ];
          };
        };
        extraPackages = ps: with ps; [
          psycopg2
          gtts
          pywizlight
          pymetno
        ];
        extraComponents = [
          "caldav"
        ];
      };
      postgresql = {
        enable = true;
        ensureDatabases = [ dbName ];
        ensureUsers = [
          {
            name = userName;
            ensurePermissions = {
              "DATABASE ${dbName}" = "ALL PRIVILEGES";
            };
          }
        ];
      };
    };
    systemd = {
      services = {
        home-assistant = {
          preStart = ''
            rm --force ${cfg.configDir}/secrets.yaml
            ln --symbolic ${cfg.secretsYaml} ${cfg.configDir}/secrets.yaml
          '';
        };
      };
    };
    reverseProxy = {
      domains = {
        "${cfg.hostname}" = {
          port = cfg.http_port;
        };
      };
    };
  };
  options = {
    services = {
      home-assistant = {
        hostname = lib.mkOption {
          type = lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]";
          description = "DNS name on which to serve home-assistant internally and externally";
          default = "home-assistant.${config.networking.domain}";
        };
        http_port = lib.mkOption {
          type = lib.types.port;
          description = "Port on which to serve home-assistant on; note home-assistant will be reverse-proxied, so clients will never see this port.";
          default = lib.trivial.warn "Consider hiding this internal detail" 38751;
        };
        secretsYaml = lib.mkOption {
          type = lib.types.path;
          description = "See https://www.home-assistant.io/docs/configuration/secrets/";
          default = "/dev/null";
        };
      };
    };
  };
}
