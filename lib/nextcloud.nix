/*
Note: to reset the state, run

sudo rm --recursive --force /var/lib/nextcloud
sudo --user postgres psql --command 'DROP DATABASE nextcloud;'
*/
{ config, pkgs, lib, ... }:
let
  makeNextcloudApp = {
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
    };
  cfg = config.services.nextcloud;
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/nextcloud.nix#L51C3-L62C6
  occ = pkgs.writeScriptBin "nextcloud-occ" ''
    #! ${pkgs.runtimeShell}
    cd ${cfg.package}
    sudo=exec
    if [[ "$USER" != nextcloud ]]; then
      sudo='exec /run/wrappers/bin/sudo -u nextcloud --preserve-env=NEXTCLOUD_CONFIG_DIR --preserve-env=OC_PASS'
    fi
    export NEXTCLOUD_CONFIG_DIR="${cfg.datadir}/config"
    $sudo \
      ${cfg.phpPackage}/bin/php \
      occ "$@"
  '';
in
{
  config = {
    services = {
      nextcloud = {
        hostName = "nextcloud.${config.networking.domain}";
        https = true;
        appstoreEnable = false;
        database = {
          createLocally = true;
        };
        caching = {
          apcu = true;
          redis = true;
          memcached = false;
        };
        logLevel = 2 /* warning */;
        logType = lib.trivial.warn "Move syslog to systemd once we install php-systemd" "syslog";
        configureRedis = true;
        enableImagemagick = true;
        config = {
          dbtype = "pgsql";
          adminuser = "root";
          trustedProxies = [ "${config.localIP}" ];
          defaultPhoneRegion = "US";
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
        extraOptions = lib.attrsets.optionalAttrs config.externalSmtp.enable ({
          mail_smtpmode = "smtp";
          mail_sendmailmode = "smtp";
          mail_smtpsecure = config.externalSmtp.security;
          mail_smtphost = config.externalSmtp.host;
          mail_smtpport = builtins.toString config.externalSmtp.port;
          mail_from_address = config.externalSmtp.fromUser;
          mail_domain = config.externalSmtp.fromDomain;
          mail_smtpauth = if config.externalSmtp.authentication then 1 else 0;
        } // lib.attrsets.optionalAttrs config.externalSmtp.authentication{
          mail_smtpname = config.externalSmtp.username;
        });
        secretFile =
          if config.externalSmtp.enable && config.externalSmtp.authentication
          then "/run/secrets/nextcloud-smtp.json"
          else null
        ;
        # notify_push = {
        #   enable = true;
        # };
        extraApps = {
          # See https://github.com/helsinki-systems/nc4nix/blob/main/27.json
          calendar = makeNextcloudApp rec {
            pname = "calendar";
            version = "4.5.0";
            hash = "sha256-McoYHnNBoOUjxL5RE3R9l7DwK3BHPvQ8VKhjef2e2kg=";
            url = "https://github.com/nextcloud-releases/${pname}/releases/download/v${version}/${pname}-v${version}.tar.gz";
          };
          notes = makeNextcloudApp rec {
            pname = "notes";
            version = "4.8.1";
            hash = "sha256-BfH1W+7TWKZRuAAhKQEQtlv8ePTtJQvZQVMMu3zULR4=";
            url = "https://github.com/nextcloud-releases/${pname}/releases/download/v${version}/${pname}.tar.gz";
          };
          contacts = makeNextcloudApp rec {
            pname = "contacts";
            version = "5.3.2";
            hash = "sha256-1jQ+pyLBPU7I4wSPkmezJq7ukrQh8WPErG4J6Ps3LR4=";
            url = "https://github.com/nextcloud-releases/${pname}/releases/download/v${version}/${pname}-v${version}.tar.gz";
          };
          # memories = makeNextcloudApp {
          #   pname = "memories";
          #   version = "v5.2.1";
          #   hash = "sha256-qu+LrohAVBpTj/t14BinT2ExDF8uifcfEpc4YB+Q9Pw=";
          # };
          # nextcloud-breeze-dark = makeNextcloudApp {
          #   pname = "nextcloud-breeze-dark";
          #   version = "v26.0.0";
          #   hash = "sha256-CKgs/IqwebPIxvcItF0Z/ynEAgcE0jhyVkxJ603QARc=";
          # };
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

            redir /.well-known/carddav   /remote.php/dav 301
            redir /.well-known/caldav    /remote.php/dav 301
            redir /.well-known/webfinger /index.php/.well-known/webfinger
            redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo

            # root /store-apps/* ${cfg.home}
            @store_apps path_regexp ^/store-apps
            root @store_apps ${cfg.home}

            # root /nix-apps/* ${cfg.home}
            @nix_apps path_regexp ^/nix-apps
            root @nix_apps ${cfg.home}

            root * ${cfg.package}

            @davClnt {
              header_regexp User-Agent ^DavClnt
              path /
            }
            redir @davClnt /remote.php/webdev{uri} 302

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

            php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
              # Tells nextcloud to remove /index.php from URLs in links
              env front_controller_active true
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
          enterMaintenanceMode = "${occ}/bin/nextcloud-occ maintenance:mode --on";
          exitMaintenanceMode = "${occ}/bin/nextcloud-occ maintenance:mode --off";
          keep_daily = 6;
          keep_monthly = 5;
          keep_yearly = 5;
        };
      };
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
        script = ''echo {\"mail_smtppassword\":\"$(cat ${config.externalSmtp.passwordFile})\"}'';
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
