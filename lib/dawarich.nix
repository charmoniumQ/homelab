{ config, ... }: {
  config = {
    services = {
      dawarich = {
        enable = true;
        webPort = 3861;
        localDomain = "dawarich.samgrayson.me";
        configureNginx = false;
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
        };
      };
    };
  };
}
