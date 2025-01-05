{ config, ... }: rec {
  assertions = [
    {
      assertion = builtins.all
        (db: db.name == db.owner)
        (builtins.attrValues config.paas.sql.databases)
      ;
      message = "NixOS Postgres module does not provide a way to set owner to a user of a different name than the DB.";
    }
  ];
  paas = {
    sql = {
      port = services.postgresql.settings.port;
      socket = "/run/postgresql";
    };
  };
  services = {
    postgresql = {
      enable = true;
      settings = {
        port = 5342;
      };
      enableJIT = true;
      ensureUsers = builtins.map
        (db: {
          name = db.name;
          ensureDBOwnership = true;
        })
        (builtins.attrValues config.paas.sql.databases)
      ;
    };
  };
}
