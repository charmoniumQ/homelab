{ config, lib, ... }:
let
  cfg = config.services.plausible;
in {
  services = {
    plausible = {
      enable = true;
      mail = {
        email = "${config.externalSmtp.fromUser}@${config.externalSmtp.fromDomain}";
        smtp = {
          enableSSL = true;
          hostAddr = "${config.externalSmtp.host}";
          hostPort = config.externalSmtp.port;
          passwordFile = "${config.externalSmtp.passwordFile}";
          user = "${config.externalSmtp.fromUser}";
        };
      };
      server = {
        baseUrl = "https://plausible.${config.networking.domain}";
        port = lib.trace "TODO: move to hash" 49321;
      };
    };
  };
  reverseProxy = lib.attrsets.optionalAttrs cfg.enable {
    domains = {
      "plausible.${config.networking.domain}" = {
        port = cfg.server.port;
      };
    };
  };
}
