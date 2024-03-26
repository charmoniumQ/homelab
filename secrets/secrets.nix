let
  sysadminKeys = (import ../hosts/site.nix {}).sysadmin.sshKeys;
  hostKeys = [
    (import ../hosts/home-server/hardware-configuration.nix { config = null; lib = null; pkgs = null; }).hostKey
  ];
  keys = sysadminKeys ++ hostKeys;
in {
  "nextcloud-adminpass.age" = { publicKeys = keys; };
  "smtp-pass.age" = { publicKeys = keys; };
  "vaultwarden-admin-token.age" = { publicKeys = keys; };
  "namecheapPassword.age" = { publicKeys = keys; };
  "resticPassword.age" = { publicKeys = keys; };
  "restic.env.age" = { publicKeys = keys; };
  "home-assistant-secrets.yaml.age" = { publicKeys = keys; };
  "zigbee2mqttSecrets.yaml.age" = { publicKeys = keys; };
  "kea-ctrl-agent-pass.age" = { publicKeys = keys; };
  "firefly-iii-app-key.age" = { publicKeys = keys; };
  "firefly-iii-postgres.age" = { publicKeys = keys; };
  "paperless.age" = { publicKeys = keys; };
}

/*
Secrets can be generated with:
pwgen 30 1
nix develop --command agenix --edit $FILE
Put in hosts/home-server/default.nix
*/
