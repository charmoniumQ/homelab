{ config, lib, ... }:
{
  config = {
    services = {
      caddy = {
        email = config.sysadmin.email;
        virtualHosts = (
          builtins.mapAttrs (name: opts: {
            extraConfig = ''
              header Strict-Transport-Security max-age=15552000;
              encode gzip zstd
              ${lib.optionalString opts.internalOnly "@internal remote_ip private_ranges"}
              reverse_proxy ${lib.optionalString opts.internalOnly "@internal"} ${opts.host}:${builtins.toString opts.port} {
                ${opts.extraProxyConfig}
              }
              ${opts.extraHostConfig}
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
