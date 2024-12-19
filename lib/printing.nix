{ config, pkgs, ... }: {
  hardware = {
    sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };
  };
  users = {
    users = {
      "${config.sysadmin.username}" = {
        extraGroups = [ "scanner" "lp" ];
      };
    };
  };
  services = {
    printing = {
      enable = true;
      drivers = [
        pkgs.gutenprint
        pkgs.hplipWithPlugin
      ];
      browsing = true;
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
