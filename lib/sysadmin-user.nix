{ config, lib, ... }:
{
  config = {
    nix = {
      settings = {
        trusted-users = [ "${config.sysadmin.username}" ];
      };
    };
    users = {
      mutableUsers = false;
      users = {
        "${config.sysadmin.username}" = {
          isNormalUser = true;
          createHome = true;
          extraGroups = [ "wheel" ];
          initialHashedPassword = config.sysadmin.hashedPassword;
          openssh = {
            authorizedKeys = {
              keys = config.sysadmin.sshKeys;
            };
          };
        };
      };
    };
    security = {
      sudo = {
        wheelNeedsPassword = false;
      };
    };
  };
  options = {
    sysadmin = {
      username = lib.mkOption {
        type = lib.types.strMatching "[a-z0-9.-]+";
        description = "UNIX username for the system administrator.";
        default = "sysadmin";
      };
      email = lib.mkOption {
        type = lib.types.strMatching "[a-z0-9.+-]+@[a-z0-9.-]+";
        description = "Email for alerts and ACME.";
      };
      sshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "SSH public key used for administrative access.";
      };
      hashedPassword = lib.mkOption {
        type = lib.types.str;
        description = ''
          User's hashed password; use `nix run nixpkgs#mkpasswd` to generate.

          There are three reasons I like to use password for sudo:
          1. It gives the user a chance to interupt a script that uses sudo without otherwise asking.
          2. If someone steals sysadmin.sshKeys, they still can't run commands as root.
          3. It gives the user a chance to "think twice" about running a command, especially if they tapped enter by accident.
        '';
      };
    };
  };
}
