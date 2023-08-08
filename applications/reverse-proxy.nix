{ config, lib, ... }:
{
  options.reverse-proxy.domains = {
    datasets = lib.mkOption {
      description = "Set a reverse proxy from reverse-proxy.<name> to reverse-proxy.<name>.<upstream>";
      type = types.attrsOf (types.submodule {
        options = {
          upstream = lib.mkOption {
            type = types.str;
          };
          healthcheck = lib.mkOption {
            type = types.boolean;
            default = true;
            description = "Whether to check the status of of downstream continuously";
            /* TODO: implement */
          };
        };
      });
      default = { };
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
        email = ;
      };
    };
  };
}
