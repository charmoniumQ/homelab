{ pkgs, lib, config, ... }:
let
  cfg = config.services.grocy;
in {
  users = {
    users = {
      grocy = {
        isSystemUser = true;
        createHome = true;
        home = cfg.dataDir;
        group = "grocy";
      };
    };
    groups = {
      grocy = {};
    };
  };
  services = {
    grocy = lib.attrsets.optionalAttrs cfg.enable {
      hostName = "grocy.${config.networking.domain}";
      settings = {
        # The default currency in the system for invoices etc.
        # Please note that exchange rates aren't taken into account, this
        # is just the setting for what's shown in the frontend.
        currency = "USD";

        # The display language (and locale configuration) for grocy.
        culture = "en";

        calendar = {
          # Whether or not to show the week-numbers
          # in the calendar.
          showWeekNumber = false;

          # Index of the first day to be shown in the calendar (0=Sunday, 1=Monday,
          # 2=Tuesday and so on).
          firstDayOfWeek = 1;
        };
      };
    };
    phpfpm = lib.attrsets.optionalAttrs cfg.enable {
      pools = {
        grocy = {
          "listen.owner" = config.services.caddy.user;
          "listen.group" = config.services.caddy.group;
        };
      };
    };
    nginx = lib.attrsets.optionalAttrs cfg.enable {
      enable = lib.mkForce false;
    };
    caddy = lib.attrsets.optionalAttrs cfg.enable {
      virtualHosts = {
        "${cfg.hostName}" = {
          extraConfig = ''
            # Based on the working ./nextcloud.nix config
            # Also see https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/grocy.nix

            encode gzip zstd

            header {
              Strict-Transport-Security max-age=31536000
              Permissions-Policy interest-cohort=()
              X-Content-Type-Options nosniff
              X-Frame-Options SAMEORIGIN
              Referrer-Policy no-referrer
              X-XSS-Protection "1; mode=block"
              X-Permitted-Cross-Domain-Policies none
              X-Robots-Tag "noindex, nofollow"
              -X-Powered-By
            }

            @immutable {
              path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
              query v=*
            }
            header @immutable Cache-Control "max-age=15778463, immutable"

            @static {
              path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
              not query v=*
            }
            header @static Cache-Control "max-age=15778463"


            @woff2 path *.woff2
            header @woff2 Cache-Control "max-age=604800"

            root * ${config.services.nginx.virtualHosts.${cfg.hostName}.root}

            php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
              root ${config.services.nginx.virtualHosts.${cfg.hostName}.root}
              # Tells nextcloud to remove /index.php from URLs in links
              env front_controller_active true
              env modHeadersAvailable true
            }

            file_server
        '';
        };
      };
    };
  };
}
