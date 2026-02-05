{ pkgs, config, ... }: {
  services = {
    garage = {
      enable = true;
      package = pkgs.garage_1;
      settings = {
        replication_factor = 1;
        rpc_bind_addr = "[::]:3901";
        rpc_public_addr = "127.0.0.1:3901";
        s3_api = {
          s3_region = "garage";
          api_bind_addr = "[::]:3900";
          root_domain = "s3.garage.${config.networking.domain}";
        };
        s3_web = {
          bind_addr = "[::]:3902";
          root_domain = "web.garage.${config.networking.domain}";
          index = "index.html";
        };
        admin = {
          api_bind_addr = "0.0.0.0:3903";
        };
      };
    };
  };
  # https://garagehq.deuxfleurs.fr/documentation/cookbook/reverse-proxy/
  reverseProxy = {
    domains = {
      "s3.garage.${config.networking.domain}" = {
        port = 3900;
      };
      "avatars.s3.garage.${config.networking.domain}" = {
        port = 3900;
      };
      "avatars.web.garage.${config.networking.domain}" = {
        port = 3902;
      };
      "admin.garage.${config.networking.domain}" = {
        port = 3903;
      };
    };
  };
}
