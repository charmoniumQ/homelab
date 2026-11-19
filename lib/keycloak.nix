{ config, lib, ... }:
let
  cfg = config.services.keycloak;
  localDb = cfg.database.createLocally && cfg.database.host == "localhost";
  dbName = if localDb then "keycloak" else cfg.database.name;
  dbUser = if localDb then "keycloak" else cfg.database.username;
  # The NixOS module wraps the package with the generated keycloak.conf and
  # plugins, but only exposes that wrapper in the systemd service path.
  keycloakBuild = lib.findFirst
    (p: lib.hasInfix "keycloak" (baseNameOf (toString p)))
    cfg.package
    config.systemd.services.keycloak.path;
in {
  services = {
    keycloak = {
      enable = true;
      database = {
        createLocally = true;
        type = "postgresql";
        port = config.services.postgresql.settings.port;
      };
      settings = {
        hostname = "https://keycloak.${config.networking.domain}";
        hostname-strict-https = false;
        http-port = 38513;
        http-enabled = true;
        # https://www.keycloak.org/server/hostname#_using_a_reverse_proxy
        proxy-headers = "xforwarded";
      };
    };
  };
  reverseProxy = {
    domains = {
      "${builtins.elemAt (builtins.split "://" cfg.settings.hostname) 2}" = {
        port = cfg.settings.http-port;
      };
    };
  };
  backups = {
    volumes = {
      keycloak = {
        filesystem = {
          paths = [ "/tmp/snapshots/keycloak-realms" ];
        };
        postgresql = {
          databases = [ dbName ];
        };
        services = [ "keycloak" ];
        # Keycloak must be stopped while exporting realms from its database.
        postStop = ''
          export_dir=/tmp/snapshots/keycloak-realms
          mkdir -p "$export_dir"
          home="$(mktemp -d)"
          trap 'rm -rf "$home"' EXIT
          mkdir -p "$home/conf"
          ln -s ${keycloakBuild}/lib "$home/lib"
          ln -s ${keycloakBuild}/providers "$home/providers"
          ln -s ${keycloakBuild}/themes "$home/themes"
          for realm in home master; do
            KC_HOME_DIR="$home" \
            KC_CONF_DIR="$home/conf" \
            KC_DB_PASSWORD="$(cat ${cfg.database.passwordFile})" \
              ${keycloakBuild}/bin/kc.sh export --optimized \
                --db=postgres \
                --db-url=jdbc:postgresql://localhost:${toString cfg.database.port}/${dbName} \
                --db-username=${dbUser} \
                --realm "$realm" \
                --file "$export_dir/$realm.json" \
                --users same_file
          done
        '';
        keep_daily = 3;
        keep_monthly = 3;
        keep_yearly = 3;
      };
    };
  };
}
