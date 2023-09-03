{ config, lib, ... }:
{
  options = {
    fastCgi = {
      domains = lib.mkOption {
        description = "Set a proxy to fastCGI https://{reverse-proxy.{name}} to unix://{reverse-proxy.{name}.socket}";
        type = lib.types.attrsOf (lib.types.submodule {
          socket = lib.mkOption {
            type = lib.types.str;
            description = "Socket of a Fast CGI process; try `config.services.phpfpm.pools.{pool}.socket`";
          };
        });
        default = { };
      };
    };
    reverseProxy = {
      domains = lib.mkOption {
        description = "Set a reverse proxy from https://{reverse-proxy.{name}} to http://{reverse-proxy.{name}.host}:{reverse-proxy.{name}.port}";
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              description = "Upstream host to forward to.";
              default = "127.0.0.1";
            };
            port = lib.mkOption {
              type = lib.types.int;
              description = "Upstream port to forward to.";
            };
            internalOnly = lib.mkOption {
              type = lib.types.bool;
              description = "Whether or not too accept connections on the WAN.";
            };
            healthcheck = lib.mkOption {
              type = lib.types.boolean;
              default = true;
              description = "Whether to check the status of of downstream continuously";
              /* TODO: implement */
            };
          };
        });
        default = { };
      };
    };
  };
}
