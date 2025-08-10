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
        # https://wiki.nixos.org/wiki/Scanners
        pkgs.hplip
        pkgs.utsushi
        pkgs.sane-airscan
        # List of supported scanners: https://gitlab.com/utsushi/utsushi
        pkgs.epkowa
        # List of supported scanners: https://www.gsp.com/cgi-bin/man.cgi?topic=sane-epkowa

        # (pkgs.epsonscan2.override { withNonFreePlugins = true; withGui = true; } )
        # pkgs.hplipWithPlugin
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
    udev = {
      packages = [
        pkgs.sane-airscan
        pkgs.utsushi
      ];
    };
    printing = {
      enable = true;
      drivers = [
        # See https://nixos.wiki/wiki/Printing
        pkgs.gutenprint
        pkgs.epson-escpr
        pkgs.epson-escpr2
        pkgs.hplip

        # Proprietary
        # pkgs.gutenprintBin
        # pkgs.hplipWithPlugin
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
