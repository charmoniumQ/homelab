{ config, pkgs, ... }:
let
  homeserverPort = 57261;
  appservicePort = 29317;
  user = "mautrix-telegram";
in {
  nixpkgs = {
    config = {
      permittedInsecurePackages = [
        "olm-3.2.16"
      ];
    };
  };
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
    mautrix-telegram = {
      package = pkgs.mautrix-telegram.override {
        python3 = pkgs.python3.override {
          packageOverrides = self: super: {
            python-olm = super.python-olm.override (super-olm: {
              olm = super-olm.olm.overrideAttrs {
                meta.knownVulnerabilities = [];
              };
            });
          };
        };
      };
      enable = true;
      registerToSynapse = true;
      environmentFile = config.age.secrets."mautrix-secrets.env".path;
      # https://github.com/mautrix/telegram/blob/master/mautrix_telegram/example-config.yaml
      settings = {
        homeserver = {
          address = "http://localhost:${builtins.toString homeserverPort}";
          domain = config.networking.domain;
        };
        appservice = {
          address = "http://localhost:${builtins.toString appservicePort}";
          hostname = "127.0.0.1";
          port = appservicePort;
          database = "postgres:///mautrix-meta?host=/var/run/postgresql/";
          public = {
            prefix = "";
            external = "https://telegram.mautrix.${config.networking.domain}";
          };
        };
        bridge = {
          permissions = {
            "*" = "relay";
            "${config.networking.domain}" = "full";
            "@admin:{conig.networking.domain}" = "admin";
          };
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
      "telegram.mautrix.samgrayson.me" = {
        port = appservicePort;
      };
    };
  };
}
