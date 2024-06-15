{ pkgs, ...}: {
  systemd = {
    services = {
      wayvnc = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        name = "wayvnc.service";
        service = "${pkgs.wayvnc}/bin/wayvnc";
      };
    };
  };
}
