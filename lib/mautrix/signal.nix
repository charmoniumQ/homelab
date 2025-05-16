{ config, pkgs, ... }:
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
      package = pkgs.mautrix-signal.override (super: {
        olm = super.olm.overrideAttrs {
          meta.knownVulnerabilities = [];
        };
      });
      enable = true;
      registerToSynapse = true;
      settings = builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommand "yaml-to-json" {
            appservicePort = builtins.toString appservicePort;
            homserverPort = builtins.toString homeserverPort;
            domain = config.networking.domain;
          } "${pkgs.yq}/bin/yq . ${./signal.yaml} | ${pkgs.envsubst}/bin/envsubst > $out"
        )
      );
    };
  };
  reverseProxy = {
    domains = {
      "signal.mautrix.samgrayson.me" = {
        port = appservicePort;
      };
    };
  };
}
