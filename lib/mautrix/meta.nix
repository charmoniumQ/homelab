{ pkgs, config, ... }:
let
  facebookAppservicePort = 29321;
  instagramAppservicePort = 29320;
  homeserverPort = 57261;
in {
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "mautrix-meta-facebook" "mautrix-meta-instagram" ];
      ensureUsers = [
        {
          name = "mautrix-meta-facebook";
          ensureDBOwnership = true;
        }
        {
          name = "mautrix-meta-instagram";
          ensureDBOwnership = true;
        }
      ];
    };
    mautrix-meta = {
      package = pkgs.mautrix-meta.override (super: {
        olm = super.olm.overrideAttrs {
          meta.knownVulnerabilities = [];
        };
      });
      instances = {
        facebook = {
          enable = true;
          registerToSynapse = true;
          environmentFile = config.age.secrets."mautrix-secrets.env".path;
          settings = {
            network = {
              mode = "facebook";
            };
            homeserver = {
              address = "http://localhost:${builtins.toString homeserverPort}";
              domain = config.networking.domain;
            };
            appserves = {
              address = "http://localhost:${builtins.toString facebookAppservicePort}";
              public_address = "https://meta.mautrix.${config.networking.domain}";
              hostname = "127.0.0.1";
              port = facebookAppservicePort;
              id = "facebook";
              bot = {
                username = "facebookbot";
              };
            };
            database = {
              type = "postgres";
              uri = "postgres:///mautrix-meta-facebook?host=/var/run/postgresql/";
            };
            bridge = {
              permissions = {
                "*" = "relay";
                "${config.networking.domain}" = "user";
                "@admin:${config.networking.domain}" = "admin";
              };
            };
            encryption = {
              allow = true;
              default = true;
            };
            double_puppet = {
              servers = {
                "samgrayson.me" = "as_token:$MATRIX_DOUBLE_PUPPETTING_AS_TOKEN";
              };
            };
          };
        };
        instagram = {
          enable = true;
          registerToSynapse = true;
          environmentFile = config.age.secrets."mautrix-secrets.env".path;
          settings = {
            # See meta.yaml as example
            network = {
              mode = "instagram";
            };
            homeserver = {
              address = "http://localhost:${builtins.toString homeserverPort}";
              domain = config.networking.domain;
            };
            appserves = {
              address = "http://localhost:${builtins.toString instagramAppservicePort}";
              public_address = "https://meta.mautrix.${config.networking.domain}";
              hostname = "127.0.0.1";
              port = instagramAppservicePort;
              id = "instagram";
              bot = {
                username = "instagram";
              };
            };
            database = {
              type = "postgres";
              uri = "postgres:///mautrix-meta-instagram?host=/var/run/postgresql/";
            };
            bridge = {
              permissions = {
                "*" = "relay";
                "${config.networking.domain}" = "user";
                "@admin:${config.networking.domain}" = "admin";
              };
            };
            encryption = {
              allow = true;
              default = true;
            };
            double_puppet = {
              servers = {
                "samgrayson.me" = "as_token:$MATRIX_DOUBLE_PUPPETTING_AS_TOKEN";
              };
            };
          };
        };
      };
    };
  };
  reverseProxy = {
    domains = {
      "facebook.mautrix.samgrayson.me" = {
        port = facebookAppservicePort;
      };
      "instagram.mautrix.samgrayson.me" = {
        port = instagramAppservicePort;
      };
    };
  };
}
