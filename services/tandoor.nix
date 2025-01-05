{ config, lib, ... }: {
  imports = [
    ../impl/reverse-proxy.nix
    ../impl/sql.nix
    ../impl/openid.nix
  ];
  assertions = [
    {
      assertion = !builtins.isNull config.paas.sql.socket;
    }
  ];
  services = {
    tandoor-recipes = {
      enable = true;
      port = 14739; # ./string_to_port.py tandoor-recipes
      extraConfig = rec {
        DB_ENGINE = {
          postgres = "platform.sql django.db.backends.postgresql";
        }."${config.paas.sql.provider}";
        POSTGRES_HOST = "localhost";
        POSTGRES_USER = "tandoor";
        POSTGRES_DB = POSTGRES_USER;
      };
    };
  };
  paas = {
    sql = {
      ensureDatabasesAndUsers = [
        config.services.tandoor-recipes.POSTGRES_USER
      ];
    };
    reverseProxy = {
      domains = {
        "tandoor.${config.endOptions.dns.defaultApex}" = {
          reverseProxy = {
            port = config.services.tandoor-recipes.port;
          };
        };
      };
    };
  };
}
