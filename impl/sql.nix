{ config, lib, ... }: let
  unixUsername = (import ./nixlib/unix-username.nix) lib;
in {
  imports = [
    ./sql/postgres.nix
  ];
  options = {
    paas = {
      sql = {
        provider = lib.mkOption {
          type = lib.types.enum [ "postgres" ];
          default = "postgres";
        };
        port = lib.mkOption {
          type = lib.types.port;
        };
        socket = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
        };
        databases = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
              name = lib.mkOption {
                type = unixUsername;
                default = name;
              };
              owner = lib.mkOption {
                type = unixUsername;
                default = name;
              };
              backedUp = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether tables in this database should be backed up automatically.";
              };
            };
          }));
        };
        ensureDatabasesAndUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };
}
