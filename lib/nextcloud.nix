/*
TODO: TOTP
*/
{ config, pkgs, lib, ... }:
let
  makeNextcloudApp = lib.trivial.warn "Compile Nextcloud plugins with composer and NPM instead of this external repository" ({
    pname
    , version
    , hash
    , url
  }:
    # TODO: Compile these with Composer and NPM by hand instead of relying on external repository.
    pkgs.stdenv.mkDerivation {
      src = pkgs.fetchurl { inherit url hash; };
      inherit pname;
      inherit version;
      buildPhase = ''
        mkdir $out
        cp --recursive * $out
      '';
      checkPhase = ''
      if [ ! -f "$out/appinfo/info.xml" ]; then
        echo "appinfo/info.xml doesn't exist in $out, aborting!"
        exit 2
      fi
    '';
    });
  occ = "/run/current-system/sw/bin/nextcloud-occ";
  cfg = config.services.nextcloud;
in
{
  config = {
    services = {
      nextcloud = {
        # enable should be set by client
        enableImagemagick = true;
        # package shoudl be set by client
        appstoreEnable = false;
        caching = {
          # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/caching_configuration.html
          # Unless you have a memcached cluster, I think just apcu + redis is recommended
          apcu = true;
          redis = true;
          memcached = false;
        };
        config = {
          adminuser = "root";
          # adminpassfile should be set by client
          dbtype = "pgsql";
        };
        configureRedis = true;
        database = {
          createLocally = true;
        };
        extraApps = {
          calendar = config.services.nextcloud.package.packages.apps.calendar;
          notify_push = config.services.nextcloud.package.packages.apps.notify_push;
        };
        hostName = lib.mkDefault "nextcloud.${config.networking.domain}";
        https = true;
        notify_push = {
          enable = true;
          logLevel = "warn";
        };
        # phpExtraExtensions = all: [
        #   all.php-systemd
        # ];
        phpOptions = {
          "opcache.jit" = "1255";
          "opcache.jit_buffer_size" = "128M";
          "opcache.interned_strings_buffer" = "16";
          # https://spot13.com/pmcalculator/
        };
        secretFile =
          if config.externalSmtp.enable && config.externalSmtp.authentication
          then "/run/secrets/nextcloud-smtp.json"
          else null
        ;
        settings = {
          default_phone_region = "US";
          loglevel = 2 /* warning */;
          logfile = "nextcloud.log";
          log_type = "file";
          # Note that Nextcloud's self-check requires logType = "file"
          # or else:
          #
          #     Failed to get an iterator for log entries: Logreader application only supports "file" log_type
          #
          # which necessitates some options in config.services.nextcloud.settings
          # See https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/logging_configuration.html
          # Perhaps we don't need Nextcloud's self-check, in which case, we should get php-systemd installed, use systemd, and log warnings.
          # That way, we will get alerts when Nextcloud has warnings.
          overwriteprotocol = "https";
          trusted_proxies = [ "${config.localIP}" ];
          mail_smtpmode = "smtp";
          mail_sendmailmode = "smtp";
          mail_smtpsecure = config.externalSmtp.security;
          mail_smtphost = config.externalSmtp.host;
          mail_smtpport = builtins.toString config.externalSmtp.port;
          mail_from_address = config.externalSmtp.fromUser;
          mail_domain = config.externalSmtp.fromDomain;
          mail_smtpauth = if config.externalSmtp.authentication then 1 else 0;
          maintenance_window_start = 1;
        } // lib.attrsets.optionalAttrs config.externalSmtp.authentication {
          mail_smtpname = config.externalSmtp.username;
        };
      };
      phpfpm = lib.attrsets.optionalAttrs cfg.enable {
        pools = {
          nextcloud = {
            settings = {
              "listen.owner" = config.services.caddy.user;
              "listen.group" = config.services.caddy.group;
            };
          };
        };
      };
      nginx = {
        enable = false;
      };
      caddy = lib.attrsets.optionalAttrs cfg.enable {
        virtualHosts = {
          "${cfg.hostName}" = {
            extraConfig = ''
            # https://github.com/NixOS/nixpkgs/issues/243203#issue-1802143563
            # https://caddy.community/t/example-docker-nextcloud-fpm-caddy-v2-webserver/9407
            encode gzip zstd

            header Strict-Transport-Security max-age=15552000;

            redir /.well-known/carddav   /remote.php/dav/ 301
            redir /.well-known/caldav    /remote.php/dav/ 301
            redir /.well-known/webfinger /index.php/.well-known/webfinger
            redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo

            @store_apps path_regexp ^/store-apps
            root @store_apps ${cfg.home}

            # @nix_apps path_regexp ^/nix-apps
            # root @nix_apps ${cfg.home}

            @davClnt {
              header_regexp User-Agent ^DavClnt
              path /
            }
            redir @davClnt /remote.php/webdev{uri} 302

            @notify_push {
              path /push
              path /push/*
            }
            reverse_proxy @notify_push unix/${cfg.notify_push.socketPath}

            # .htaccess / data / config / ... shouldn't be accessible from outside
            @sensitive {
              # ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)
              path /build     /build/*
              path /tests     /tests/*
              path /config    /config/*
              path /lib       /lib/*
              path /3rdparty  /3rdparty/*
              path /templates /templates/*
              path /data      /data/*
        
              # ^/(?:\.|autotest|occ|issue|indie|db_|console)
              path /.*
              path /autotest*
              path /occ*
              path /issue*
              path /indie*
              path /db_*
              path /console*
            }
            respond @sensitive 404

            root * ${cfg.package}

            php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
              # Tells nextcloud to remove /index.php from URLs in links
              env front_controller_active true
              trusted_proxies private_ranges
            }
            file_server
          '';
          };
        };
      };
      redis = {
        # https://github.com/jemalloc/jemalloc/issues/1328
        # (Suggested for Background Saving: http://redis.io/topics/faq) .
        vmOverCommit = true;
      };
      # TODO: write fail2ban filter and jail for Caddy/Nextcloud
      # https://www.ericlight.com/moving-to-the-caddy-web-server.html
    };
    backups = {
      volumes = {
        nextcloud = {
          # https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html
          filesystem = {
            paths = [ "${cfg.datadir}/data" ];
          };
          postgresql = {
            databases = [ cfg.config.dbname ];
          };
          services = [ ];
          enterMaintenanceMode = "${occ} maintenance:mode --on";
          exitMaintenanceMode = "${occ} maintenance:mode --off";
          keep_daily = 2;
          keep_monthly = 2;
          keep_yearly = 2;
        };
      };
    };
    dns = {
      localDomains = [ "${config.services.nextcloud.hostName}" ];
    };
    users = lib.attrsets.optionalAttrs cfg.enable {
      groups = {
        nextcloud = {
          members = [ "nextcloud" config.services.caddy.user ];
        };
      };
    };
    environment = lib.attrsets.optionalAttrs cfg.enable {
      systemPackages = [
        pkgs.zstd
        pkgs.gzip
      ];
    };
    generatedFiles = lib.attrsets.optionalAttrs (cfg.enable && config.externalSmtp.enable && config.externalSmtp.authentication) {
      "nextcloud-smtp.json" = {
        name = "nextcloud-smtp.json";
        script = ''echo {\"mail_smtppassword\":\"$(cat ${config.externalSmtp.passwordFile} | tr --delete '\n')\"}'';
        user = config.services.phpfpm.pools.nextcloud.user;
        group = config.services.phpfpm.pools.nextcloud.group;
      };
    };
    # runtimeTests = {
    #   tests = {
    #     nextcloud-uses-redis = {
    #       user = "nextcloud";
    #       script = ''
    #         ${services.redis.package}/bin/redis-cli -s ${config.services.redis.servers.nextcloud.unixSocket} monitor > log &
    #         monitor_pid=$?
    #         ${pkgs.curl}/bin/curl https://${ocnfig.services.nextcloud.hostName}/
    #         kill $?
    #       '';
    #     };
    #   };
    # };
  };
}
