let
  sysadminKey = builtins.elemAt (import ../hosts/site.nix {}).sysadmin.sshKeys 0;
  hostKey = (import ../hosts/home-server {config = null; modulesPath = null; lib = null; pkgs = null; }).hostKey;
in {
  "home-server-secrets.age".publicKeys = [ sysadminKey hostKey ];
}
