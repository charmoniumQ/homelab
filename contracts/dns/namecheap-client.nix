{ lib, nixlib, config, pkgs, shb, ... }:
let
  cfg = config.namecheap-client;

  # This is a pretty good Python API wrapper for Namecheap's HTTP API
  # https://github.com/adriangalilea/namecheap-python
  namecheap-python = pypkgs: pypkgs.buildPythonPackage rec {
    pname = "namecheap-python";
    version = "1.0.4";
    src = pkgs.fetchPypi {
      pname = "namecheap_python";
      inherit version;
      sha256 = "a6c44fba607ab9f2a6ce0b8c26e0ec631e4583ae3deca231c4765fc7c9e9022c";
    };
    propagatedBuildInputs = [
      pypkgs.httpx
      pypkgs.pydantic
      pypkgs.python-dotenv
      pypkgs.rich
      pypkgs.xmltodict
      pypkgs.tldextract
    ];
    pyproject = true;
    pythonImportsCheck = [ "namecheap" ];
  };

  # Yes, a.py = ... will work as expected in Nix lang.
  namecheap-client.py = nixlib.checked-python-script {
    pname = "namecheap-client";
    script = ./namecheap-client.py;
    pypkgs-fn = pypkgs: [
      (namecheap-python pypkgs)
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
        namecheap-client = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          script = "${namecheap-client.py} ${pkgs.writeTextFile (builtins.toJSON cfg)}";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.systemd.user;
            Group = cfg.systemd.group;
          };
        };
      };
      timers = {
        namecheap-client = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            Unit = "namecheap-client.service";
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
    namecheap-client = {
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
              restartUnits = [ "namecheap-client.service" ];
            };
          };
        };
      };
      sandbox = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "namecheap-client";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "namecheap-client";
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
