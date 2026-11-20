{ config, ... }: {
  config = {
    services = {
      dawarich = {
        enable = true;
        webPort = 3861;
        localDomain = "dawarich.samgrayson.me";
        configureNginx = false;
        environment = {
          APPLICATION_URL = "https://dawarich.samgrayson.me";
          OIDC_CLIENT_ID = "dawarich";
          OIDC_ISSUER = "https://keycloak.samgrayson.me/realms/home";
          OIDC_PROVIDER_NAME = "Home SSO";
          OIDC_AUTO_REGISTER = "true";
          ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
          ALLOW_EMAIL_PASSWORD_LOGIN = "false";
        };
        extraEnvFiles = [ config.sops.templates."dawarich-secrets.env".path ];
        smtp = {
          host = config.externalSmtp.host;
          port = config.externalSmtp.port;
          user = config.externalSmtp.username;
          passwordFile = config.externalSmtp.passwordFile;
        };
      };
    };
    reverseProxy = {
      domains = {
        "${config.services.dawarich.localDomain}" = {
          port = config.services.dawarich.webPort;
          extraProxyConfig = ''
            encode brotli {
              match {
                content_type
                  text/css
                  text/plain
                  text/xml
                  text/x-component
                  text/javascript
                  application/x-javascript
                  application/javascript
                  application/json
                  application/manifest+json
                  application/vnd.api+json
                  application/xml
                  application/xhtml+xml
                  application/rss+xml
                  application/atom+xml
                  application/vnd.ms-fontobject
                  application/x-font-ttf
                  application/x-font-opentype
                  application/x-font-truetype
                  image/svg+xml
                  image/x-icon
                  image/vnd.microsoft.icon
                  font/ttf
                  font/eot
                  font/otf
                  font/opentype
              }
            }
          '';
        };
      };
    };
    sops = {
      secrets = {
        "dawarich/oidc_client_secret" = { };
      };
      templates = {
        "dawarich-secrets.env" = {
          content = ''
            OIDC_CLIENT_SECRET="${config.sops.placeholder."dawarich/oidc_client_secret"}"
          '';
          owner = config.services.dawarich.user;
          group = config.services.dawarich.group;
        };
      };
    };
  };
}
