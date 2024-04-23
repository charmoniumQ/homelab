{ pkgs, lib, config, firefly, ... }: let
  data-importer = pkgs.php83.buildComposerProject (finalAttrs: {
    pname = "data-importer";
    version = "1.4.5";
    src = pkgs.fetchFromGitHub {
      owner = "firefly-iii";
      repo = "data-importer";
      rev = "v${finalAttrs.version}";
      hash = "sha256-o2W5TibTG/BQoOWg6jMZl0tO/zmrefcvb1LlLlYL2Hk=";
    };
    composerLock = ./composer.lock;
    vendorHash = "sha256-uDBm+QWbj6Uq+DG4ZNTGyeALyLB3tLYdZwZI5j+PUJI=";
  }).overrideAttrs (oldAttrs: {
    installPhase = oldAttrs.installPhase + ''
      rm -R $out/storage
      ln -s /var/lib/firefly-iii-data-importer/storage $out/storage
      ln -fs /var/lib/firefly-iii-data-importer/storage/.env $out/.env
    '';
  });
in {
  options = {
    services = {
      firefly-iii = {
        data-importer = {
          enable = lib.mkEnableOption "Firefly III data-importer";
          dataDir = lib.mkOption {
            description = "Firefly III data directory";
            default = "/var/lib/firefly-iii-data-importer";
            type = lib.types.path;
          };

          # Reverse proxy
          hostname = lib.mkOption {
            type = lib.types.str;
            default =
              if config.networking.domain != null then
                config.networking.fqdn
              else
                config.networking.hostName;
            hostname = "firefly-iii-data-importer.${config.networking.domain}";
            description = "The hostname to serve Firefly III on.";
          };

          # User management
          user = lib.mkOption {
            default = "fireflydataimporter";
            description = "User Firefly III data importer runs as.";
            type = lib.types.str;
          };

          group = lib.mkOption {
            default = "fireflydataimporter";
            description = "Group Firefly III data importer runs as.";
            type = lib.types.str;
          };
        };
      };
    };
  };
  config = lib.mkIf config.services.firefly-iii.data-importer.enable {
    services = {
      phpfpm = {
        pools = {
          firefly-iii-data-importer = {
            user = config.services.firefly-iii.data-importer.user;
            group = config.services.firefly-iii.data-importer.group;
            phpPackage = pkgs.php83;
            phpOptions = ''
              log_errors = on
            '';
            settings = {
              "listen.mode" = "0660";
              "listen.owner" = config.services.firefly-iii.data-importer.user;
              "listen.group" = config.services.firefly-iii.data-importer.user;
            };
          };
        };
      };
      caddy = {
        virtualHosts = {
          "${config.services.firefly-iii.data-importer.hostname}" = {
            extraConfig = ''
              encode gzip zstd
              header Strict-Transport-Security max-age=15552000;
              try_files {path} {path}/ {path}/index.php?{query}
              root * ${data-importer}/share/php/data-importer/public
              php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii-data-importer.socket} { }
              file_server
            '';
          };
        };
      };
    };
    dns = {
      localDomains = [ "${config.services.firefly-iii.data-importer.hostname}" ];
    };
    users = {
      users = {
        "${config.services.firefly-iii.data-importer.user}" = {
          isSystemUser = true;
          group = "${config.services.firefly-iii.data-importer.group}";
        };
        "${config.services.caddy.user}".extraGroups = [ config.services.firefly-iii.data-importer.group ];
      };
      groups = {
        "${config.services.firefly-iii.data-importer.group}" = {};
      };
    };
  };
    systemd.services.firefly-iii-data-importer-setup = {
      description = "Preparation tasks for Firefly III Data Importer";
      before = [ "phpfpm-firefly-iii-data-importer.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = config.services.firefly-iii.data-importer.user;
        WorkingDirectory = data-importer;
      };
      script =
        let
          fireflyEnv = pkgs.writeText "firefly-iii.env" (fireflyEnvVars filteredConfig);
        in
        ''
          set -exuo pipefail
          umask 077

          # create the .env file
          install -T -m 0600 -o ${user} ${fireflyEnv} "${cfg.dataDir}/.env"

          # migrate db
          ${pkgs.php83}/bin/php artisan migrate --force -vvv
        '';
    };
}
