let
  sysadminKey = builtins.elemAt (import ../hosts/site.nix {}).sysadmin.sshKeys 0;
  hostKey = (import ../hosts/home-server/hardware-configuration.nix { lib = null; pkgs = null; }).hostKey;
in {
  "nextcloud-adminpass.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "nextcloud-smtp-pass.age" = { publicKeys = [ sysadminKey hostKey ]; };
}

/*
Secrets can be generated with:
pwgen 30 1
nix develop --command agenix --edit $FILE
*/
