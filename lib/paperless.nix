{ config, lib, ... }: let
  port = 37152;
  smtp = config.externalSmtp;
in lib.mkIf config.services.paperless.enable {
  services = {
    paperless = {
      extraConfig = {
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_REDIS = "redis:///run/redis/redis.sock";
        PAPERLESS_URL = "https://paperless.${config.networking.domain}";
        PAPERLESS_EMAIL_HOST = smtp.host;
        PAPERLESS_EMAIL_PORT = smtp.port;
        PAPERLESS_EMAIL_HOST_USER = smtp.username;
        PAPERLESS_EMAIL_FROM = smtp.username;
        PAPERLESS_EMAIL_HOST_PASSWORD = lib.trivial.warn "TODO: smtp password file" smtp.passwordFile;
        PAPERLESS_EMAIL_USE_TLS = smtp.security == "starttls";
        PAPERLESS_EMAIL_USE_SSL = smtp.security == "ssl";
      };
    };
    redis = {
      servers = {
        paperless = {
          enable = config.services.paperless.enable;
          user = config.services.paperless.user;
        };
      };
    };
  };
  reverseProxy = {
    domains = {
      "paperless.${config.networking.domain}" = {
        inherit port;
      };
    };
  };
}
