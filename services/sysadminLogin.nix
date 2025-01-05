{ lib, ... }: {
  imports = [
    ../impl/sysadminAccounts.nix
  ];
  options = {
    endOptions = {
      sysadmins = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options = {
            username = lib.mkOption {
              type = (import ../nixlib/unix-username.nix) lib;
              description = "UNIX username for the system administrator.";
              default = name;
            };
            sshKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
            };
            hashedPassword = lib.mkOption {
              type = lib.types.str;
              description = "User's hashed password; use `nix run nixpkgs#mkpasswd` to generate.";
            };
          };
        }));
      };
    };
  };
}
