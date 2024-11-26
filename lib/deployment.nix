{ config, lib, pkgs, ... }:
{
  config = {
    environment = {
      systemPackages = [
        # Bare minimum
        # Most stuff should actually be defined in home-manager
        pkgs.emacs
        pkgs.htop
        pkgs.tmux
        pkgs.curl
        pkgs.coreutils
        pkgs.bash
      ];
    };
    programs = {
      atop = {
        enable = true;
      };
    };
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
          initialHashedPassword = lib.trivial.warn "Move this to a hashedPasswordFile" config.sysadmin.hashedPassword;
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
    deployment = {
      username = lib.mkOption {
        type = lib.types.strMatching "[a-z0-9.-]+";
        description = "UNIX username for the system administrator.";
        default = "sysadmin";
      };
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "DNS name or IP to host (or 'localhost' for non-remote build)";
      };
      sudo = lib.mkOption {
        type = lib.types.bool;
        description = "Use remote or local sudo";
      };
    };
  };
}
