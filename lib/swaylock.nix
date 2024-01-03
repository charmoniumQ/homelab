{ pkgs, ... }:
let
  lock = pkgs.writeShellScriptBin "lock" ''
    ${pkgs.swaylock-effects}/bin/swaylock \
      --indicator \
      --clock \
      --screenshots \
      --effect-blur 60x1
    '';
in {
  environment = {
    systemPackages = [ lock ];
  };
  systemd = {
    user = {
      services = {
        "swaylock.unit" = {
          enable = true;
          before = [ "sleep.target" ];
          wantedBy = [ "sleep.target" ];
          description = "Local system suspend actions";
          script = "${lock}/bin/lock";
          serviceConfig = {
            Type = "simple";
          };
        };
      };
    };
  };
}
