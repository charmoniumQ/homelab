{
  config
, ...
}:
let
  cfg = config.services.immich;
in {
  services = {
    immich = {
      enable = true;
      redis = {
        enable = true;
      };
      database = {
        enable = true;
        createDB = true;
      };
      machine-learning = {
        enable = true;
      };
      settings = {
        server = {
          externalDomain = "https://immich.samgrayson.me";
        };
      };
    };
    # https://github.com/dubrowin/Immich-backed-by-S3
    immich-public-proxy = {
      enable = true;
      immichUrl = "localhost:${cfg.port}";
    };
    reverseProxy = {
      domains = {
        "immich.${config.networking.domain}" = {
          port = cfg.port;
        };
      };
    };
  };
}
