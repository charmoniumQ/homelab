
{ pkgs, config, lib, ... }: let
  cfg = config.services.paperless;
  smtp = config.externalSmtp;
  # See https://docs.allauth.org/en/latest/socialaccount/providers/openid_connect.html
  socialaccount_provider_config = {
    openid_connect = {
        # Optional PKCE defaults to False, but may be required by your provider
        # Can be set globally, or per app (settings).
        OAUTH_PKCE_ENABLED = true;
        APPS = [
            {
                provider_id = "keycloak";
                name = "Home SSO";
                client_id = "paperless-ngx";
                secret = config.sops.placeholder."smtp/password";
                settings = {
                    # When enabled, an additional call to the userinfo
                    # endpoint takes place. The data returned is stored in
                    # `SocialAccount.extra_data`. When disabled, the (decoded) ID
                    # token payload is used instead.
                    fetch_userinfo = true;
                    oauth_pkce_enabled = true;
                    server_url = "https://keycloak.samgrayson.me/realms/home/.well-known/openid-configuration";
                    # Optional token endpoint authentication method.
                    # May be one of "client_secret_basic", "client_secret_post"
                    # If omitted, a method from the the server's
                    # token auth methods list is used
                    token_auth_method = "client_secret_basic";
                    # The field to be used as the account ID.
                    uid_field = "sub";
                    # Optional overrides for the OpenID Connect
                    # configuration fetched from the server's
                    # .well-known/openid-configuration endpoint.
                    openid_configuration_overrides = {
                        token_endpoint = "https://my.server.example.com/custom/token";
                    };
                };
            }
        ];
    };
};
in {
  services = {
    paperless = {
      enable = true;
      port = 37152;
      settings = {
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_REDIS = "unix:///run/redis-paperless/redis.sock";
        PAPERLESS_URL = "https://paperless.${config.networking.domain}";
        PAPERLESS_EMAIL_HOST = smtp.host;
        PAPERLESS_EMAIL_PORT = smtp.port;
        PAPERLESS_EMAIL_HOST_USER = smtp.username;
        PAPERLESS_EMAIL_FROM = smtp.username;
        PAPERLESS_EMAIL_HOST_PASSWORD = lib.trivial.warn "TODO: smtp password file" smtp.passwordFile;
        PAPERLESS_EMAIL_USE_TLS = smtp.security == "starttls";
        PAPERLESS_EMAIL_USE_SSL = smtp.security == "ssl";
      };
      environmentFile = config.sops.templates."paperless-secrets.env".path;
    };
    redis = {
      servers = {
        paperless = {
          enable = config.services.paperless.enable;
          user = config.services.paperless.user;
        };
      };
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "paperless" ];
      ensureUsers = [
        {
          name = "paperless";
          ensureDBOwnership = true;
        }
      ];
    };
  };
  sops = {
    templates = {
      "paperless-secrets.env" = {
        content = ''
          PAPERLESS_EMAIL_HOST_PASSWORD=${config.sops.placeholder."smtp/password"}
          PAPERLESS_SOCIALACCOUNT_PROVIDERS=${builtins.toJSON socialaccount_provider_config}
        '';
        owner = cfg.user;
        group = cfg.group;
      };
    };
  };
  reverseProxy = {
    domains = {
      "paperless.${config.networking.domain}" = {
        inherit (cfg) port;
        host = "127.0.0.1";
      };
    };
  };
}
