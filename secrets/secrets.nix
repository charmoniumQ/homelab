let
  sysadminKey = builtins.elemAt (import ../hosts/site.nix { config = null; }).sysadmin.sshKeys 0;
  hostKey = (import ../hosts/home-server/hardware-configuration.nix { lib = null; pkgs = null; }).hostKey;
in {
  "nextcloud-adminpass.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "smtp-pass.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "vaultwarden-admin-token.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "namecheapPassword.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "resticPassword.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "restic.env.age" = { publicKeys = [ sysadminKey hostKey ]; };
  "home-assistant-secrets.yaml.age" = { publicKeys = [ sysadminKey hostKey ]; };
}

/*
Secrets can be generated with:
pwgen 30 1
nix develop --command agenix --edit $FILE
*/
