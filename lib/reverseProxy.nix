{ config, lib, ... }:
{
  config = {
    dns = {
      localDomains = lib.debug.traceVal builtins.attrNames config.reverseProxy.domains;
    };
    networking = {
      firewall = {
        allowedTCPPorts = lib.lists.optionals
          ([] != (builtins.attrNames config.reverseProxy.domains))
          [ 80 443 ];
      };
    };
  };
  options = {
    reverseProxy = {
      domains = lib.mkOption {
        description = "Set a reverse proxy from https://{reverse-proxy.{name}} to http://{reverse-proxy.{name}.host}:{reverse-proxy.{name}.port}";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]";
              description = "Upstream host to forward to.";
              default = "127.0.0.1";
            };
            extraProxyConfig = lib.mkOption {
              type = lib.types.lines;
              description = "Additional configuration options to place in this server block.";
              default = "";
            };
            extraHostConfig = lib.mkOption {
              type = lib.types.lines;
              description = "Additional configuration options to place in this server block.";
              default = "";
            };
            port = lib.mkOption {
              type = lib.types.port;
              description = "Upstream port to forward to.";
            };
            internalOnly = lib.mkOption {
              type = lib.types.bool;
              description = "Whether or not too accept connections on the WAN.";
              default = false;
            };
            healthcheck = lib.mkOption {
              type = lib.types.boolean;
              default = true;
              description = "Whether to check the status of of downstream continuously";
              # TODO: implement healthchecks
            };
          };
        });
      };
    };
  };
}
