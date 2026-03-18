{ config, pkgs, ... }:
{
  services = {
    mysql = {
      enable = true;
      ensureDatabases = [ "matomo" ];
      ensureUsers = [ {
        name = "matomo";
        ensurePermissions = {
          "matomo.*" = "ALL PRIVILEGES";
        };
      } ];
      # INSTALL PLUGIN unix_socket SONAME 'auth_socket';
      # ALTER USER 'matomo'@'localhost' IDENTIFIED WITH unix_socket;
    };
    matomo = {
      enable = true;
      webServerUser = "caddy";
      hostname = "matomo.${config.networking.domain}";
    };
    caddy = {
      virtualHosts = {
        "${config.services.matomo.hostname}" = {
          extraConfig = ''
            root * ${config.services.matomo.package}/share

            # Security headers
            header {
              Referrer-Policy origin
              X-Content-Type-Options nosniff
              X-XSS-Protection "1; mode=block"

              # Optional HSTS (6 months)
              # Strict-Transport-Security "max-age=15768000"
            }

            # Allow only specific PHP entry points
            @php_allowed {
              path_regexp phpfiles ^/(index|matomo|piwik|js/index|plugins/HeatmapSessionRecording/configs)\.php$
            }

            php_fastcgi @php_allowed unix/${config.services.phpfpm.pools.matomo.socket} {
              env HTTP_PROXY ""
            }

            # Deny all other PHP files
            @php_denied {
              path *.php
              not path_regexp phpfiles ^/(index|matomo|piwik|js/index|plugins/HeatmapSessionRecording/configs)\.php$
            }
            respond @php_denied 403

            # Disable access to sensitive directories
            @blocked_dirs {
              path_regexp blocked ^/(config|tmp|core|lang|libs|vendor|misc|node_modules)(/|$)
            }
            respond @blocked_dirs 403

            # Block .ht* files
            @htfiles {
              path_regexp htfiles ^/\.ht
            }
            respond @htfiles 403

            # Disable caching for Matomo preview JS
            @preview_js {
              path_regexp preview js/container_.*_preview\.js$
            }
            header @preview_js {
              Cache-Control "private, no-cache, no-store"
            }

            # Cache static assets for 1 hour
            @static {
              path *.gif *.ico *.jpg *.png *.svg *.js *.css *.htm *.html *.mp3 *.mp4 *.wav *.ogg *.avi *.ttf *.eot *.woff *.woff2
            }
            header @static {
              Cache-Control "public"
              Pragma public
            }

            # Render text files correctly
            @textfiles {
              path *.md /LEGALNOTICE /LICENSE
            }
            header @textfiles {
              Content-Type text/plain
            }

            # Serve files (handles index.php automatically via php_fastcgi)
            file_server
          '';
        };
      };
    };
  };
}
