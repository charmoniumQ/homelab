{ lib, nixlib, config, pkgs, shb, ... }:
let
  cfg = config.namecheap-client;

  # Yes, a.py = ... will work as expected in Nix lang.
  namecheap-client.py = nixlib.checked-python-script {
    pname = "namecheap-client";
    script = ./namecheap-client.py;
    pypkgs-fn = pypkgs: [
      pypkgs.typer
      pypkgs.aiohttp
      pypkgs.aiodns
    ];
    inherit pkgs;
  };
in {
  config = {
    users = {
      users = {
        "${cfg.user}" = {
          isSystemUser = true;
          group = cfg.group;
        };
      };
      groups = {
        "${cfg.group}" = { };
      };
    };
    systemd = {
      services = {
        porkbun-client = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          script = "${porkbun-client.py} ${pkgs.writeTextFile (builtins.toJSON cfg)}";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.systemd.user;
            Group = cfg.systemd.group;
          };
        };
      };
      timers = {
        porkbun-client = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            Unit = "porkbun-client.service";
            Persistent = true;
            OnCalendar = cfg.date;
            User = cfg.systemd.user;
            Group = cfg.systemd.group;
          };
        };
      };
    };
  };
  options = {
    porkbun-client = {
      authentication = {
        username = lib.mkOption {
          type = lib.types.str;
        };
        api-user = lib.mkOption {
          type = lib.types.str;
        };
        api-key-file = lib.mkOption {
          type = lib.types.submodule {
            options = shb.contracts.secret.mkRequester {
              owner = cfg.user;
              group = cfg.group;
              restartUnits = [ "porkbun-client.service" ];
            };
          };
        };
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "porkbun-client";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "porkbun-client";
      };
      delete-other-records = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to delete records not described declaratively.";
        default = false;
      };
      timer = lib.mkOption {
        type = lib.types.str;
        description = "See <https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events>";
        default = "1h";
      };
    };
  };
}
