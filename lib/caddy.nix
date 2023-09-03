{ config, lib, ... }:
{
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
      virtualHosts = (
        builtins.mapAttrs (name: opts: {
          extraConfig = ''
            @internal remote_ip private_ranges
            reverse_proxy ${lib.optionalString opts.internalOnly "@internal"} ${opts.host}:${builtins.toString opts.port}
          '';
        }) config.reverseProxy.domains
      ) ++ (
        builtins.mapAttrs (name: opts: {
          extraConfig = ''
            @internal remote_ip private_ranges
            php_fastcgi ${lib.optionalString opts.internalOnly "@internal"} ${opts.socket}
          '';
        }) config.fastCgi.domains
      );
    };
    prometheus = {
      exporters = {
        caddy = {
          enable = true;
          port = 3523;
        };
      };
    };
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
    };
  };
}
