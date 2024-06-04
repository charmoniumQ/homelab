{ config, ... }:
{
  services = {
    plausible = {
      enable = true;
      adminUser = {
        # activate is used to skip the email verification of the admin-user that's
        # automatically created by plausible. This is only supported if
        # postgresql is configured by the module. This is done by default, but
        # can be turned off with services.plausible.database.postgres.setup.
        activate = true;
        email = config.sysadmin.email;
      };
      server = {
        baseUrl = "https://plausible-analytics.${config.networking.domain}";
        # secretKeybaseFile = "/run/secrets/plausible-secret-key-base";
        # Run `openssl rand -base64 64` to generate the secret
      };
    };
  };
}
