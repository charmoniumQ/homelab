{ config, pkgs, ... }: {
  /*
  Epson EcoTank 2400: http://download.ebz.epson.net/dsc/search/01/search/searchModuleFromResult
  - ESC/P-R, epson-escpr or epson-escpr2 in Nix
  - Epson Scan 2, epsonscan2 in Nix
  - Epson Print Utility for Linux, gutenprint (bin/escputil) in Nix
  */
  hardware = {
    sane = {
      enable = true;
      extraBackends = [
        pkgs.hplipWithPlugin
        # Don't need the open-source drivers if I use the proprietary ones
        # pkgs.utsushi
        # pkgs.epkowa
        (pkgs.epsonscan2.override { withNonFreePlugins = true; withGui = true; } )
      ];
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
        pkgs.epson-escpr
        pkgs.epson-escpr2
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
