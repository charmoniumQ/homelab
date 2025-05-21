{ config, pkgs, ... }:
let
  homeserverPort = 57261;
  appservicePort = 29318;
  user = "mautrix-whatsapp";
in {
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ user ];
      ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
        }
      ];
    };
    mautrix-whatsapp = {
      package = pkgs.mautrix-whatsapp.override (super: {
        olm = super.olm.overrideAttrs {
          meta.knownVulnerabilities = [];
        };
      });
      enable = true;
      registerToSynapse = true;
      environmentFile = config.age.secrets."mautrix-secrets.env".path;
      settings = {
        homeserver = {
          address = "http://localhost:${builtins.toString homeserverPort}";
          domain = config.networking.domain;
        };
        appservice = {
          address = "http://localhost:${builtins.toString appservicePort}";
          hostname = "127.0.0.1";
          port = appservicePort;
          public_address = "https://whatsapp.mautrix.${config.networking.domain}";
        };
        database = {
          uri = "postgres:///mautrix-meta?host=/var/run/postgresql/";
        };
        public_media = {
          enabled = true;
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
  reverseProxy = {
    domains = {
      "whatsapp.mautrix.samgrayson.me" = {
        port = appservicePort;
      };
    };
  };
}
