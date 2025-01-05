{ config, lib, ... }:
{
  assertions = [
    {
      assertion = builtins.all
        (cfg: (builtins.isNull cfg.phpFastCgi) != (builtins.isNull cfg.reverseProxy))
        (builtins.attrValues config.paas.reverseProxy.domains)
      ;
    }
  ];
  services = {
    caddy = {
      email = config.endOptions.webmasterEmail;
      virtualHosts = (
        builtins.mapAttrs (name: opts:
          let
            redirectsPaths = builtins.mapAttrs (_: opts: "redir ${opts.from} ${opts.to} ${opts.httpCode}") opts.redirectPaths;
            forbidPaths = builtins.mapAttrs (_: opts: "error ${opts.path} ${opts.code}") opts.forbidPaths;
            immutablePaths = builtins.mapAttrs (_: opts: "header ${opts.path} Cache-Control \"max-age=15778463, immutable\"") opts.immutablePaths;
            phpFastCgi = lib.strings.optionalString (!builtins.isNull opts.phpFastcgi) ''
              php_fasgcgi unix/${opts.phpFastCgi.socket} {
                root ${opts.phpFastCgi.phpRoot}
              }
              file_server {
                root ${opts.phpFastCgi.staticRoot}
              }
            '';
            reverseProxy = lib.strings.optionalString (!builtins.isNull opts.reverseProxy) ''
              reverse_proxy ${opts.host}:${builtins.toString opts.port}
            '';
          in {
            extraConfig = ''
              header Strict-Transport-Security max-age=15552000;
              encode gzip zstd
              ${builtins.concatStringsSep "\n" redirectsPaths}
              ${builtins.concatStringsSep "\n" forbidPaths}
              ${builtins.concatStringsSep "\n" immutablePaths}
              ${phpFastCgi}${reverseProxy}
            '';
          }) (builtins.attrValues config.paas.reverseProxy.domains)
      );
    };
  };
}
