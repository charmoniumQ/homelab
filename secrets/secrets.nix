let
  sysadminKeys = (import ../hosts/site.nix { config = null; }).sysadmin.sshKeys;
  hostKeys = [
    (import ../hosts/home-server/hardware-configuration.nix { lib = null; pkgs = null; }).hostKey
  ];
in {
  "nextcloud-adminpass.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "smtp-pass.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "vaultwarden-admin-token.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "namecheapPassword.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "resticPassword.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "restic.env.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "home-assistant-secrets.yaml.age" = { publicKeys = sysadminKeys ++ hostKeys; };
  "zigbee2mqttSecrets.yaml.age" = { publicKeys = sysadminKeys ++ hostKeys; };
}

/*
Secrets can be generated with:
pwgen 30 1
nix develop --command agenix --edit $FILE
*/
