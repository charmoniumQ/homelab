{ config, lib, ... }:
{
  config = {
    services = {
      /*
      Everything in NixOS is preconfigured with nginx, but I'll likely have to modify the config anyway.
      Caddy has a *much* simpler config file, so I think it will be more maintainable by me in the long run.
      */
      caddy = {
        email = config.sysadmin.email;
        virtualHosts = (
          builtins.mapAttrs (name: opts: {
            extraConfig = ''
             header Strict-Transport-Security max-age=15552000;
             ${lib.optionalString opts.internalOnly "@internal remote_ip private_ranges"}
             reverse_proxy ${lib.optionalString opts.internalOnly "@internal"} ${opts.host}:${builtins.toString opts.port}
           '';
          }) config.reverseProxy.domains
        );
      };
    };
    warnings =
      if (config.services.caddy.enable && config.services.nginx.enable)
      then ["Nginx and Caddy are both enabled; consider consolidating to just one"]
      else [];
  };
}
