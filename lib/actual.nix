{ config, ... }:
rec {
  reverseProxy = {
    domains = {
      "budget.${config.networking.domain}" = {
        port = services.actual.settings.port;
      };
    };
  };
  services = {
    actual = {
      enable = true;
      settings = {
        port = 19243;
        loginMethod = "openid";
        allowedLoginMethods = ["password" "openid"];
        openId = {
          "discoveryURL" = "https://keycloak.samgrayson.me/realms/home/.well-known/openid-configuration";
          "client_id" = "actualbudget";
          #"client_secret" = # TODO: incorporate this from file
          "server_hostname" = "your Actual Server URL (so the provider redirects you to this)";
          "authMethod" = "openid";
        };
      };
    };
  };
  sops = {
    secrets = {
      "actual_budget/oidc_client_secret" = {
        owner = config.services.actual.user;
        group = config.services.actual.group;
      };
    };
  };
}
