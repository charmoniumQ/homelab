{ lib, config, firefly, ... }: let
  cfg = config.services.firefly-iii;
  pkg = config.systemd.services.firefly-iii-setup.serviceConfig.WorkingDirectory;
in {
  # imports = [
  #   firefly.nixosModules.firefly-iii
  # ];
  config = {
    services = {
      # postgresql = {
      #   enable = true;
      #   ensureDatabases = [ cfg.database.name ];
      #   ensureUsers = [ {
      #     name = cfg.database.user;
      #     ensurePermissions = { "${cfg.database.name}.*" = "ALL PRIVILEGES"; };
      #   } ];
      # };
      # caddy = {
      #   virtualHosts = {
      #     cfg.hostname = {
      #       extraConfig = ''
      #         encode gzip zstd
      #         header Strict-Transport-Security max-age=15552000;
      #         try_files {path} {path}/ {path}/index.php?{query}
      #         root * ${pkg}/public
      #         php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} { }
      #         file_server
      #       '';
      #     };
      #   };
      # };
      # nginx = {
      #   enable = false;
      # };
      firefly-iii = {
        config = {
          DB_SOCKET = "/run/postgresql";
          DB_PORT = lib.mkForce "";
          DB_HOST = lib.mkForce "";
        };
        enable = true;
        appURL = "https://firefly.samgrayson.me";
        hostname = "firefly.samgrayson.me";
        user = "firefly";
        group = "firefly";
        database = {
          type = "pgsql";
          host = "";
          port = 0;
          name = "firefly";
          user = "firefly";
          createLocally = false;
        };
        mail = {
          driver = "smtp";
          host = config.externalSmtp.host;
          port = config.externalSmtp.port;
          user = config.externalSmtp.username;
          passwordFile = config.externalSmtp.passwordFile;
          encryption = if config.externalSmtp.security == "ssl" then "tls" else null;
        };
      };
    };
    systemd = {
      services = {
        firefly-iii-setup = {
          after = lib.mkForce "postgresql.service";
        };
      };
    };
  };
}
