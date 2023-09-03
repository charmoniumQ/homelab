{ config, pkgs, ... }:
{
  services = {
    nextcloud = {
      enable = true;
      hostName = "nextcloud.${config.networking.domain}";
      https = false;
      appstoreEnable = false;
      database = {
        createLocally = true;
      };
      caching = {
        redis = true;
      };
      configureRedis = true;
      config = {
        dbtype = "pgsql";
        adminpassFile = "/TODO";
      };
      notify_push = {
        enable = true;
      };
      extraApps = {
        calendar = pkgs.fetchFromGitHub {
          owner = "nextcloud";
          repo = "calendar";
          rev = "v4.4.3";
          hash = "sha256-Xw2toEkvIE/UaUBzJdBitA21F0RqNkctQqDzIrFMm84=";
        };
        twofactor_totp = pkgs.fetchFromGitHub {
          owner = "nextcloud";
          repo = "twofactor_totp";
          rev = "v27.0.1";
          hash = "sha256-k02rXLSXJEC3GCY1MF2b2zCmat4J1/4DGmYVMkQ7QQY=";
        };
        nextcloud-breeze-dark = pkgs.fetchFromGitHub {
          owner = "mwalbeck";
          repo = "nextcloud-breeze-dark";
          rev = "v26.0.0";
          hash = "sha256-CKgs/IqwebPIxvcItF0Z/ynEAgcE0jhyVkxJ603QARc=";
        };
        memories = pkgs.fetchFromGitHub {
          owner = "pulsejet";
          repo = "memories";
          rev = "v5.2.1";
          hash = "sha256-qU+LrohAVBpTj/t14BinT2ExDF8uifcfEpc4YB+Q9Pw=";
        };
        notes = pkgs.fetchFromGitHub {
          owner = "nextcloud";
          repo = "notes";
          rev = "v4.8.1";
          hash = "sha256-P6hFrsh7Axfq8rPJIx7WjGcGaTfHuo3oNV7n5RkpvyU=";
        };
        richdocuments = pkgs.fetchFromGitHub {
          owner = "nextcloud";
          repo = "richdocuments";
          rev = "v8.1.0";
          hash = "sha256-5le3HTww2njQ6VMhPSHlKTf0a4EgCbUezli8Pry5eyc=";
        };
      };
    };
    prometheus = {
      exporters = {
        nextcloud = {
          enable = true;
        };
      };
    };
  };
  fastCgi = {
    domains = {
      "${config.services.nextcloud.hostName}" = {
        socket = config.services.phpfpm.pools.nextcloud.socket;
      };
    };
  };
}
