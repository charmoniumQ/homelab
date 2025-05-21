let
  args = {
    config = {
      wifi = false;
    };
    lib = null;
    pkgs = null;
    modulesPath = <nixpkgs>;
  };
  sysadminKeys = (import ../hosts/site.nix args).sysadmin.sshKeys;
  hostKeys = [
    (import ../hosts/home-server/hardware-configuration.nix  args).hostKey
    (import ../hosts/cloud-server/hardware-configuration.nix args).hostKey
    (import ../hosts/laptop/hardware-configuration.nix       args).hostKey
    (import ../hosts/tvpi/hardware-configuration.nix         args).hostKey
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
  "kea-ctrl-agent-pass.age" = { publicKeys = keys; };
  "firefly-iii-app-key.age" = { publicKeys = keys; };
  "firefly-iii-postgres.age" = { publicKeys = keys; };
  "paperless.age" = { publicKeys = keys; };
  "pia-auth-user-pass.age" = { publicKeys = keys; };
  "wifi-env-file.age" = { publicKeys = keys; };
  "plausible-secret-key.age" = { publicKeys = keys; };
  "synapse-registration.age" = { publicKeys = keys; };
  "keycloak-postgres.age" = { publicKeys = keys; };
  "garage-env.age" = { publicKeys = keys; };
  "mautrix-secrets.env.age" = { publicKeys = keys; };
}

/*
Secrets can be generated with:
pwgen 30 1
nix develop --command agenix --edit $FILE
Put in hosts/home-server/default.nix
*/
