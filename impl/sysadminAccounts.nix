{ config, lib, pkgs, ... }:
{
  environment = {
    systemPackages = [
      # Bare minimum
      # Most stuff should actually be defined in home-manager
      pkgs.emacs
      pkgs.nano
      pkgs.vim
      pkgs.htop
      pkgs.atop
      pkgs.tmux
      pkgs.curl
      pkgs.wget
      pkgs.coreutils
      pkgs.bash
      pkgs.at
      # essential to already have in case you run out of disk space (and can't do nix shell)
      pkgs.gdu
    ];
  };
  programs = {
    atop = {
      enable = true;
    };
  };
  nix = {
    settings = {
      trusted-users = builtins.map (sysadmin: sysadmin.username) (builtins.attrValues config.endOptions.sysadmins);
    };
  };
  users = {
    mutableUsers = false;
    users = builtins.mapAttrs (_: sysadmin: {
      isNormalUser = true;
      createHome = true;
      extraGroups = [ "wheel" "docker" ];
      initialHashedPassword = lib.trivial.warn "Move this to a hashedPasswordFile" sysadmin.hashedPassword;
      openssh = {
        authorizedKeys = {
          keys = sysadmin.sshKeys;
        };
      };
    }) config.endOptions.sysadmins;
  };
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
}
