{ pkgs, config, ... }:
let
  /*

  ((function() {
    // "Storage -> Cookies (HTTP-only) find d, should begin with 'xoxd-'
    const cookie = "";
    const loc = window.location.href.split("/");
    const team = loc[loc.length - 2];
    const localConfig = JSON.parse(localStorage.localConfig_v2);
    const teamConfig = localConfig.teams[team];
    console.log(teamConfig.name);
    console.log("login token " + teamConfig.token + " " + cookie);
  })());
  */
  package = pkgs.mautrix-slack.override (super: {
    olm = super.olm.overrideAttrs {
      meta.knownVulnerabilities = [];
    };
  });
  settings = builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommand "yaml-to-json" {} "${pkgs.yq}/bin/yq . ${./slack.yaml} > $out"
    )
  );
  dataDir = "/var/lib/mautrix-slack";
  registrationFile = "${dataDir}/slack.yaml";
  settingsFile = "${dataDir}/config.yaml";
  settingsFileUnsubstituted = settingsFormat.generate "mautrix-slack-config-unsubstituted.yaml" settings;
  settingsFormat = pkgs.formats.yaml { };
  appservicePort = 29335;
  homeserverPort = 57261;
  user = "mautrix-slack";
  group = "${user}";
in {
  users = {
    users = {
      "${user}" = {
        isSystemUser = true;
        group = group;
        home = dataDir;
        description = "Mautrix-Slack bridge user";
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
      "slack.mautrix.samgrayson.me" = {
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
      mautrix-slack = {
        description = "Mautrix-Slack Service - A Slack bridge for Matrix";
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
            ${package}/bin/mautrix-slack \
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
          User = "mautrix-slack";
          Group = "mautrix-slack";
          StateDirectory = baseNameOf dataDir;
          WorkingDirectory = dataDir;
          ExecStart = "${package}/bin/mautrix-slack --config='${settingsFile}' --registration='${registrationFile}'";
          Restart = "on-failure";
          RestartSec = "30s";
          Type = "simple";
        };
        restartTriggers = [ settingsFileUnsubstituted ];
      };
    };
  };
}
