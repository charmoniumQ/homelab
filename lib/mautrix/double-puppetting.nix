{ lib, pkgs, config, ... }:
let
  file = "/var/lib/matrix-synapse/double-puppetting.yaml";
in {
  services = {
    matrix-synapse = {
      settings = {
        app_service_config_files = [ file ];
      };
    };
  };
  systemd = {
    services = {
      mautrix-double-puppetting = {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "matrix-synapse.service" ];
        description = "Configures double puppetting for mautrix";
        serviceConfig = {
          Type = "oneshot";
          User = "matrix-synapse";
          Group = "matrix-synapse";
          EnvironmentFile = config.age.secrets."mautrix-secrets.env".path;
          ExecStart = "${(pkgs.writeShellScriptBin "exec-start.sh" ''
            if [ ! -f ${file} ]; then
              ${pkgs.envsubst}/bin/envsubst -i ${./double-puppetting.yaml} -o ${file}
            fi
          '')}/bin/exec-start.sh";
        };
        restartTriggers = [ ./double-puppetting.yaml ];
      };
    };
  };
}
