/*
Note: to reset the state, run

sudo rm --recursive --force /var/lib/nextcloud
sudo --user postgres psql --command 'DROP DATABASE nextcloud;'
*/
{ config, pkgs, lib, ... }:
{
  config = {
    services = {
      nextcloud = {
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
        configureRedis = true;
        enableImagemagick = true;
        config = {
          dbtype = "pgsql";
          adminuser = "root";
          trustedProxies = [ "${config.localIP}" ];
          defaultPhoneRegion = "US";
        };
        extraOptions =
          let smtp = config.services.nextcloud.smtp; in
          {} // lib.attrsets.optionalAttrs smtp.enable {
            mail_smtpmode = "smtp";
            mail_sendmailmode = "smtp";
            mail_smtpsecure = smtp.security;
            mail_smtphost = smtp.host;
            mail_smtpport = builtins.toString smtp.port;
            mail_from_address = smtp.fromUser;
            mail_domain = smtp.fromDomain;
            mail_smtpauth = if smtp.authentication then 1 else 0;
          } // lib.attrsets.optionalAttrs (smtp.enable && smtp.authentication) {
            mail_smtpname = smtp.username;
          }
        ;
        secretFile =
          let smtp = config.services.nextcloud.smtp; in
          if smtp.enable && smtp.authentication
          then smtp.passwordJsonFile
          else null
        ;
        # notify_push = {
        #   enable = true;
        # };
        extraApps = {
          # calendar = pkgs.fetchFromGitHub {
          #   owner = "nextcloud";
          #   repo = "calendar";
          #   rev = "v4.4.3";
          #   hash = "sha256-Xw2toEkvIE/UaUBzJdBitA21F0RqNkctQqDzIrFMm84=";
          # };
          # twofactor_totp = pkgs.fetchFromGitHub {
          #   owner = "nextcloud";
          #   repo = "twofactor_totp";
          #   rev = "v27.0.1";
          #   hash = "sha256-k02rXLSXJEC3GCY1MF2b2zCmat4J1/4DGmYVMkQ7QQY=";
          # };
          # nextcloud-breeze-dark = pkgs.fetchFromGitHub {
          #   owner = "mwalbeck";
          #   repo = "nextcloud-breeze-dark";
          #   rev = "v26.0.0";
          #   hash = "sha256-CKgs/IqwebPIxvcItF0Z/ynEAgcE0jhyVkxJ603QARc=";
          # };
          # memories = pkgs.fetchFromGitHub {
          #   owner = "pulsejet";
          #   repo = "memories";
          #   rev = "v5.2.1";
          #   hash = "sha256-qU+LrohAVBpTj/t14BinT2ExDF8uifcfEpc4YB+Q9Pw=";
          # };
          # notes = pkgs.fetchFromGitHub {
          #   owner = "nextcloud";
          #   repo = "notes";
          #   rev = "v4.8.1";
          #   hash = "sha256-P6hFrsh7Axfq8rPJIx7WjGcGaTfHuo3oNV7n5RkpvyU=";
          # };
          # richdocuments = pkgs.fetchFromGitHub {
          #   owner = "nextcloud";
          #   repo = "richdocuments";
          #   rev = "v8.1.0";
          #   hash = "sha256-5le3HTww2njQ6VMhPSHlKTf0a4EgCbUezli8Pry5eyc=";
          # };
        };
      };
      phpfpm = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
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
      caddy = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
        virtualHosts = {
          "${config.services.nextcloud.hostName}" = {
            extraConfig = ''
            # https://github.com/NixOS/nixpkgs/issues/243203#issue-1802143563
            # https://caddy.community/t/example-docker-nextcloud-fpm-caddy-v2-webserver/9407
            encode gzip zstd

            header Strict-Transport-Security max-age=15552000;

            redir /.well-known/carddav   /remote.php/dav 301
            redir /.well-known/caldav    /remote.php/dav 301
            redir /.well-known/webfinger /index.php/.well-known/webfinger
            redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo


            # root /store-apps/* ${config.services.nextcloud.home}
            @store_apps path_regexp ^/store-apps
            root @store_apps ${config.services.nextcloud.home}

            # root /nix-apps/* ${config.services.nextcloud.home}
            @nix_apps path_regexp ^/nix-apps
            root @nix_apps ${config.services.nextcloud.home}

            root * ${config.services.nextcloud.package}

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
    };
    users = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
      groups = {
        nextcloud = {
          members = [ "nextcloud" config.services.caddy.user ];
        };
      };
    };
    dns = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
      localDomains = [ "${config.services.nextcloud.hostName}" ];
    };
    environment = lib.attrsets.optionalAttrs config.services.nextcloud.enable {
      systemPackages = [
        pkgs.zstd
        pkgs.gzip
      ];
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
  options = {
    services = {
      nextcloud = {
        smtp = {
          enable = lib.mkOption {
            type = lib.types.bool;
            description = "Whether to allow Nextcloud server to send emails to users using the specified SMTP server.";
          };
          security = lib.mkOption {
            type = lib.types.enum [ "" "ssl" "starttls" ];
            description = "Security protocl used to access SMTP server.";
          };
          authentication = lib.mkOption {
            type = lib.types.bool;
            description = "Whether this SMTP server requires authentication.";
          };
          username = lib.mkOption {
            type = lib.types.nonEmptyStr;
            description = "Username with which to log in to the SMTP server. Defaults to \${fromUser}@\${fromDomain}";
            default = "${config.services.nextcloud.smtp.fromUser}@${config.services.nextcloud.smtp.fromDomain}";
          };
          passwordJsonFile = lib.mkOption {
            type = lib.types.path;
            description = "File of the password with which to log in to the SMTP server. Should be in the form of a JSON file like: {\"mail_smtppassword\": \"password\"} where password is replaced with the actual password.";
          };
          host = lib.mkOption {
            type = lib.types.strMatching "[a-z0-9.-]+";
            description = "Hostname of SMTP server to use.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port of SMTP server to use.";
          };
          fromUser = lib.mkOption {
            type = lib.types.nonEmptyStr;
            description = "The user-half of the \"from\" email address.";
          };
          fromDomain = lib.mkOption {
            type = lib.types.nonEmptyStr;
            description = "The domain-half of the \"from\" email address to use.";
          };
        };
      };
    };
  };
}
