{ config, lib, crowdsec, ... }: {
  imports = [
    crowdsec.nixosModules.crowdsec
  ];
  config = {
    services = {
      crowdsec = {
        enable = true;
        enrollKeyFile = config.options.endOptions.crowdsec.enrollKeyFile;
        settings = {
          api = {
            server = {
              listen_uri = "127.0.0.1:8080";
            };
          };
        };
      };
    };
  };
  options = {
    endOptions = {
      crowdsec = {
        enrollKeyFile = lib.mkOption {
          type = lib.types.path;
        };
      };
    };
  };
}
