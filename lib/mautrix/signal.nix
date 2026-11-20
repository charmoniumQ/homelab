{ config, lib, pkgs, ... }:
let
  homeserverPort = 57261;
  appservicePort = 29328;
  user = "mautrix-signal";
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
    mautrix-signal = {
      enable = true;
      environmentFile = config.age.secrets."mautrix-secrets.env".path;
      registerToSynapse = true;
      settings = builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommand "yaml-to-json" {
            appservicePort = builtins.toString appservicePort;
            homserverPort = builtins.toString homeserverPort;
            domain = config.networking.domain;
          } "${pkgs.envsubst}/bin/envsubst -i ${./signal.yaml} '$appservicePort' '$homeserverPort' '$domain' | ${pkgs.yq}/bin/yq . > $out"
        )
      );
    };
  };
  systemd.services.mautrix-signal.serviceConfig.EnvironmentFile = lib.mkForce [
    config.age.secrets."mautrix-secrets.env".path
    config.sops.templates."mautrix-pickle-keys.env".path
    config.sops.templates."mautrix-double-puppet.env".path
  ];
  reverseProxy = {
    domains = {
      "signal.mautrix.samgrayson.me" = {
        port = appservicePort;
      };
    };
  };
}
