{ pkgs, config, ... }:
let
  package = pkgs.mautrix-gmessages.override (super: {
    olm = super.olm.overrideAttrs {
      meta.knownVulnerabilities = [];
    };
  });
  settings = builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommand "yaml-to-json" {} "${pkgs.yq}/bin/yq . ${./gmessages.yaml} > $out"
    )
  );
  dataDir = "/var/lib/mautrix-gmessages";
  registrationFile = "${dataDir}/gmessages.yaml";
  settingsFile = "${dataDir}/config.yaml";
  settingsFileUnsubstituted = settingsFormat.generate "mautrix-gmessages-config-unsubstituted.yaml" settings;
  settingsFormat = pkgs.formats.yaml { };
  appservicePort = 29336;
  homeserverPort = 57261;
  user = "mautrix-gmessages";
  group = "${user}";
in {
  users = {
    users = {
      "${user}" = {
        isSystemUser = true;
        group = group;
        home = dataDir;
        description = "Mautrix-GMessages bridge user";
      };
    };
    groups = {
      "${group}" = { };
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
    matrix-synapse = {
      settings = {
        app_service_config_files = [ registrationFile ];
      };
    };
  };
  reverseProxy = {
    domains = {
      "mautrix-gmessages.samgrayson.me" = {
        port = appservicePort;
      };
    };
  };
  systemd = {
    services = {
      matrix-synapse = {
        serviceConfig = {
          SupplementaryGroups = [ group ];
        };
      };
      mautrix-gmessages = {
        description = "Mautrix-GMessages Service - A GMessages bridge for Matrix";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" "matrix-synapse.service" ];
        after = [ "network-online.target" "matrix-synapse.service" ];
        preStart = ''
          rm --force '${settingsFile}'

          export appservicePort=${builtins.toString appservicePort} \
                 homserverPort=${builtins.toString homeserverPort} \
                 domain=${config.networking.domain}

          ${pkgs.envsubst}/bin/envsubst \
            -o '${settingsFile}' \
            -i '${settingsFileUnsubstituted}'
          chmod 640 '${settingsFile}'

          # generate the appservice's registration file if absent
          if [ ! -f '${registrationFile}' ]; then
            ${package}/bin/mautrix-gmessages \
              --generate-registration \
              --config='${settingsFile}' \
              --registration='${registrationFile}'
          fi
          chmod 640 '${registrationFile}'

          as_token=$(${pkgs.yq}/bin/yq .as_token '${registrationFile}')
          hs_token=$(${pkgs.yq}/bin/yq .hs_token '${registrationFile}')
          ${pkgs.yq}/bin/yq --in-place --yaml-roundtrip \
              ".appservice.as_token = $as_token | .appservice.hs_token = $hs_token" \
              '${settingsFile}'
        '';

        serviceConfig = {
          User = "mautrix-gmessages";
          Group = "mautrix-gmessages";
          StateDirectory = baseNameOf dataDir;
          EnvironmentFile = config.age.secrets."mautrix-secrets.env".path;
          WorkingDirectory = dataDir;
          ExecStart = "${package}/bin/mautrix-gmessages --config='${settingsFile}' --registration='${registrationFile}'";
          Restart = "on-failure";
          RestartSec = "30s";
          Type = "simple";
        };
        restartTriggers = [ settingsFileUnsubstituted ];
      };
    };
  };
}
