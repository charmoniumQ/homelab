{ pkgs, config, lib, ... }:
let
  cfg = config.services.home-assistant;
  userName = "hass";
  dbName = "hass";
  mqttPort = 36134;
  zigbee2mqttPort = 18452;
  mqttTopic = "zigbee";
  mqttSocket = "/run/mqtt.sock";
in {
  config = {
    environment = {
      systemPackages = [ cfg.package ];
    };
    services = {
      home-assistant = {
        configWritable = true;
        lovelaceConfigWritable = true;
        # TODO: Remove this config as much as possible
        # TODO: Back this up in Restic
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
          automation = "!include automations.yaml";
          scene = "!include scenes.yaml";
          script = "!include scripts.yaml";
          calendar = []
            ++ (lib.lists.optional config.services.nextcloud.enable {
              platform = "caldav";
              username = "sam";
              password = "!secret nextcloud_password";
              url = "https://${config.services.nextcloud.hostName}/remote.php/dav";
              # TODO: Remove calendar names from this file
              # calendars = [ "personal_shared_by_kt" "shared" "personal" ];
            })
          ;
          light = [
            {
              platform = "hubspace";
              username = "!secret hubspace_username";
              password = "!secret hubspace_password";
              debug = true;
              friendlynames = [ "OfficeLight" ];
              roomnames = [];
            }
          ];
          recorder = {
            db_url = "postgresql://${userName}@/${dbName}?host=/run/postgresql";
          };
          lovelace = {
            # mode = "yaml";
            mode = "storage";
          };
          # tuya = {
          #   username = "!secret tuya_app_username";
          #   password = "!secret tuya_app_password";
          #   access_id = "!secret tuya_iot_id";
          #   access_secret = "!secret tuya_iot_password";
          # };
          # mqtt = [
          #   {
          #     username = "home-assistant";
          #     broker = "127.0.0.1";
          #     port = mqttPort;
          #     password = "!secret mqtt_password";
          #   }
          # ];
          http = {
            server_host = "127.0.0.1";
            server_port = cfg.http_port;
            use_x_forwarded_for = true;
            trusted_proxies = [ "127.0.0.1" ];
          };
          logger = {
            default = "warning";
          };
        };
        extraPackages = ps: with ps; [
          psycopg2
          radios
          aiogithubapi
          pyqrcode
          ical
        ];
        extraComponents = [
          "met"
          "calendar"
          "caldav"
          "wiz"
          "mqtt"
          "tuya"
          "otp"
          "zha"
          "google_translate" # for gtts
          "esphome"
         ];
      };
      # TODO: Remove mosquitto/zigbee2mqtt, secrets, and options
      mosquitto = lib.attrsets.optionalAttrs (! cfg.zha) {
        enable = cfg.enable;
        logDest = [ "syslog" ];
        logType = [ "warning" ];
        listeners = [
          {
            # address = mqttSocket;
            # port = 0;
            address = "127.0.0.1";
            port = mqttPort;
            users = {
              home-assistant = {
                passwordFile = config.generatedFiles.mosquittoHAPassword.path;
                acl = [ "readwrite ${mqttTopic}/#" ];
              };
              zigbee2mqtt = {
                passwordFile = config.generatedFiles.mosquittoZMPassword.path;
                acl = [ "readwrite ${mqttTopic}/#" ];
              };
            };
          }
        ];
      };
      zigbee2mqtt = {
        enable = ! cfg.zha;
        settings = lib.attrsets.optionalAttrs (! cfg.zha) {
          homeassistant = true;
          permit_join = false;
          mqtt = {
            base_topic = mqttTopic;
            server = "mqtt://127.0.0.1:${builtins.toString mqttPort}";
            user = "zigbee2mqtt";
            password = "!secrets.yaml mqtt_password";
          };
          frontend = {
            host = "127.0.0.1";
            port = zigbee2mqttPort;
            # host = "/run/zigbee2mqtt-frontend.sock";
          };
          serial = {
            port = cfg.zigbeeDevice;
          };
          advanced = {
            network_key = "!secrets.yaml advanced_network_key";
          };
        };
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
        zigbee2mqtt = lib.attrsets.optionalAttrs (! cfg.zha) {
          preStart = ''
            cp --no-preserve=mode ${cfg.zigbee2mqttSecretsYaml} "${config.services.zigbee2mqtt.dataDir}/secrets.yaml"
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
    generatedFiles = lib.attrsets.optionalAttrs (! cfg.zha) {
      mosquittoHAPassword = {
        name = "mosquittoHAPassword";
        script = "${pkgs.yq}/bin/yq -r .mqtt_password ${cfg.secretsYaml}";
        user = config.users.users.mosquitto.name;
        group = config.users.users.mosquitto.group;
      };
      mosquittoZMPassword = {
        name = "mosquittoZMPassword";
        script = "${pkgs.yq}/bin/yq -r .mqtt_password ${cfg.zigbee2mqttSecretsYaml}";
        user = config.users.users.mosquitto.name;
        group = config.users.users.mosquitto.group;
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
        zigbee2mqttSecretsYaml = lib.mkOption {
          type = lib.types.path;
          description = "/path/to/secrets.yaml to be provided to zigbee2mqtt; should have keys 'zigbee_network_key' and 'mqtt_password'";
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
        zigbeeDevice = lib.mkOption {
          type = lib.types.path;
          description = "Path to a Zigbee coordinator";
        };
        zha = lib.mkOption {
          type = lib.types.bool;
          description = "Use ZHA isntead of Mosquitto + zigbee2mqtt";
          default = true;
        };
      };
    };
  };
}
