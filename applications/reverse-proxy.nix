{ config, lib, ... }:
{
  options = {
    reverseProxy = {
      domains =  lib.mkOption {
        description = "Set a reverse proxy from https://{reverse-proxy.{name}} to http://{reverse-proxy.{name}.host}:{reverse-proxy.{name}.port}";
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              description = "Upstream host to forward to.";
                default = "";
            };
            port = lib.mkOption {
              type = lib.types.int;
              description = "Upstream port to forward to.";
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
  config = {
    services = {
      nginx = {
        enable = false;
      };
      /*
    Everything in NixOS is preconfigured with nginx, but I'll likely have to modify the config anyway.
    Caddy has a *much* simpler config file, so I think it will be more maintainable by me in the long run.
    */
      caddy = {
        enable = true;
        email = config.sysadmin.email;
        virtualHosts = builtins.mapAttrs (name: opts: {
          extraConfig = ''
            reverse_proxy ${opts.host}:${builtins.toString opts.port}
          '';
        }) config.reverseProxy.domains;
      };
    };
    networking = {
      firewall = {
        enable = true;
        allowedTCPPorts = builtins.sort
          builtins.lessThan
          (lib.lists.unique
            (config.networking.firewall.allowedTCPPorts ++ [ 80 443 ]));
      };
    };
  };
}
