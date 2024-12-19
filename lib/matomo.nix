{ config, ... }:
{
  services = {
    matomo = {
      enable = true;
      webServerUser = "caddy";
      hostname = "matomo.${config.networking.domain}";
    };
    mysql = {
      ensureDatabases = [ "matomo" ];
    };
    caddy = {
      virtualHosts = {
        "${config.services.matomo.hostname}" = {
          extraConfig = ''
            root * ${config.services.matomo.package}/share

            # Serve index.php as the default index
            file_server
            try_files {path} {path}/ /index.php

            # FastCGI settings for PHP files
            @php path /index.php /matomo.php /piwik.php
            php_fastcgi @php unix/${config.services.phpfpm.pools.matomo.socket}

            # Block access to specific directories
            @blockdirs path_regexp blockdirs ^/(core|lang|misc)/
            respond @blockdirs "403 Forbidden" 403

            # Block specific file types
            @blockfiles path_regexp blockfiles \.(bat|git|ini|sh|txt|tpl|xml|md)$
            respond @blockfiles "403 Forbidden" 403

            # robots.txt rule
            @robots path /robots.txt
            respond @robots "User-agent: *\nDisallow: /\n" 200

            # Cache JavaScript files
            @matomojs path /matomo.js /piwik.js
            header @matomojs Cache-Control "public, max-age=2592000"
          '';
        };
      };
    };
  };
}
