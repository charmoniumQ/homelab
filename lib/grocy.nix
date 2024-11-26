{ pkgs, lib, config, ... }:
let
  cfg = config.services.grocy;
in {

  # The default has grocy user in the nginx group
  # I don't want to use nginx
  # Therefore, I don't want the grocy user's group to be named "nginx"
  # Unfortunately, that is a bit harder than I anticipated.
  # All of the code until `### fin` is copied and mutated from [1] to accomodate this.
  # [1]: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/grocy.nix

  users = {
    users = {
      grocy = {
        isSystemUser = true;
        createHome = true;
        home = cfg.dataDir;
        group = lib.mkForce "grocy";
      };
    };
    groups = {
      grocy = {};
    };
  };
  systemd = {
    tmpfiles = {
      rules = map (
        dirName: "d '${cfg.dataDir}/${dirName}' - grocy grocy - -"
      ) [ "viewcache" "plugins" "settingoverrides" "storage" ];
    };
  };
  services = {
    phpfpm = {
      pools = {
        grocy = {
          user = lib.mkForce "grocy";
          group = lib.mkForce "grocy";
          inherit (cfg.phpfpm) settings;
          phpEnv = {
            GROCY_CONFIG_FILE = "/etc/grocy/config.php";
            GROCY_DB_FILE = "${cfg.dataDir}/grocy.db";
            GROCY_STORAGE_DIR = "${cfg.dataDir}/storage";
            GROCY_PLUGIN_DIR = "${cfg.dataDir}/plugins";
            GROCY_CACHE_DIR = "${cfg.dataDir}/viewcache";
          };
        };
      };
    };

    grocy = {
      phpfpm = {
        settings = {
          "listen.owner" = config.services.caddy.user;
          "listen.group" = config.services.caddy.group;
          "pm" = "dynamic";
          "php_admin_value[error_log]" = "stderr";
          "php_admin_flag[log_errors]" = true;
          "catch_workers_output" = true;
          "pm.max_children" = "32";
          "pm.start_servers" = "2";
          "pm.min_spare_servers" = "2";
          "pm.max_spare_servers" = "4";
          "pm.max_requests" = "500";
        };
      };

      ### fin


      enable = true;
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
    nginx = lib.attrsets.optionalAttrs cfg.enable {
      enable = lib.mkForce false;
    };
    caddy = lib.attrsets.optionalAttrs cfg.enable {
      virtualHosts = {
        "${cfg.hostName}" = {
          extraConfig = ''
            # Based on the working ./nextcloud.nix config
            # Also see https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/grocy.nix
            # With help from https://srp.life/p/setting-up-grocy-on-caddy-with-lets-encrypt-support

            encode zstd gzip

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
              path *.css *.js *.mjs *.svg *.gif *.png *.jpe?g *.ico *.wasm *.tflite *.woff2?
              query v=*
            }
            header @immutable {
                # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/grocy.nix
                Cache-Control "public, max-age=15778463";
                X-Content-Type-Options nosniff;
                X-XSS-Protection "1; mode=block";
                X-Robots-Tag none;
                X-Download-Options noopen;
                X-Permitted-Cross-Domain-Policies none;
                Referrer-Policy no-referrer;
                Cache-Control "max-age=15778463, immutable"
            }

            @php path *.php
            php_fastcgi @php unix/${config.services.phpfpm.pools.grocy.socket} {
              root ${cfg.package}/public
            }

            try_files {path} /index.php?{query} # url rewriting
            root * ${cfg.package}/public
            file_server
        '';
        };
      };
    };
  };
  dns = {
    localDomains = [ "${cfg.hostName}" ];
  };
}
