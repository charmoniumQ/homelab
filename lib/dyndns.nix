{ config, pkgs, lib, ... }:
let
  cfg = config.services.dyndns;
  jsonCfg = (pkgs.formats.json {}).generate "cfg.json" cfg;
  python_ = pkgs.python311.withPackages (pypkgs: [ pypkgs.requests pypkgs.retry ]);
  python = "${python_}/bin/python";
  script = pkgs.writeText "script.py" (builtins.readFile ./dyndns.py);
in {
  config = {
    systemd = {
      services = {
        "dyndns" = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          script = "${python} ${script} ${jsonCfg}";
          serviceConfig = {
            Type = "oneshot";
          };
        };
      };
      timers = {
        "dyndns" = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            Unit = "dyndns.service";
            Persistent = true;
            OnCalendar = config.services.dyndns.updateInterval;
            AccuracySec = config.services.dyndns.updateAccuracy;
          };
        };
      };
    };
  };
  options = {
    services = {
      dyndns = {
        updateInterval = lib.mkOption {
          type = lib.types.str;
          default = "04:00";
        };
        updateAccuracy = lib.mkOption {
          type = lib.types.str;
          default = "60m";
        };
        ipProvider = lib.mkOption {
          type = lib.types.strMatching "https?://[a-z0-9][a-z0-9./-]+[a-z0-9/]";
          default = "https://dynamicdns.park-your-domain.com/getip";
          description = "URL of a server which will respond with the client's IP";
        };
        entries = lib.mkOption {
          description = "Update the following hosts to point to the current devices external IP";
          default = [ ];
          type = lib.types.listOf (lib.types.submodule {
            options = {
              protocol = lib.mkOption {
                type = lib.types.enum [ "namecheap" ];
                description = "Protocol by which to set the dynamic DNS data";
              };
              server = lib.mkOption {
                type = lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]";
                description = "Provider of dynamic DNS";
              };
              host = lib.mkOption {
                type = lib.types.strMatching "\\*|@|[a-z0-9][a-z0-9-]+";
                description = "Name of host to update";
              };
              domain = lib.mkOption {
                type = lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]";
                description = "Domain of host to update";
                default = config.networking.domain;
              };
              passwordFile = lib.mkOption {
                type = lib.types.path;
                description = "/path/to/file containing password for the Dynamic DNS service. Note that for Namecheap, this is **not** your Namecheap account password; instead, view your automatically assigned Dynamic DNS password in Namecheap's dashboard";
              };
            };
          });
        };
      };
    };
  };
}
