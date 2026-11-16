{ lib, config, pkgs, ... }:
let
  postgresExtensions = pp: [
    pp.postgis
  ];
  # To upgrade:
  # 1. Bump newPostgres
  # 2. Deploy
  # 3. Run ssh cloud sudo upgrade-pg-cluster
  # 4. Bump oldPostgres
  # 5. Deploy
  # 6. Run ssh cloud sudo -u postgres <vacuum DB command printed out by step 3>
  # 7, Run ssh cloud sudo -u postgres /var/lib/postgresql/$n/delete_old_cluster.sh, replacing N with the new version of Postgres
  # Also see https://nixos.org/manual/nixos/stable/#module-services-postgres-upgrading
  # https://wiki.nixos.org/wiki/PostgreSQL
  oldPostgres = pkgs.postgresql_17_jit.withPackages postgresExtensions;
  newPostgres = pkgs.postgresql_17_jit.withPackages postgresExtensions;
  cfg = config.services.postgresql;
in
{
  environment = {
    systemPackages = lib.optional (oldPostgres != newPostgres) (
      pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
        export NEWBIN="${newPostgres}/bin"

        export OLDDATA="${cfg.dataDir}"
        export OLDBIN="${cfg.finalPackage}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}

        sudo -u postgres "$NEWBIN/pg_upgrade" \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
          --jobs=$(nproc) --link \
          "$@"
      ''
      );
  };
  services = {
    postgresql = {
      enable = true;
      package = oldPostgres;
      settings = {
        port = 5432;
      };
      enableJIT = true;
    };
  };
}
