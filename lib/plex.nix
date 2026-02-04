{ config, ... }:
let
  jellyfinHttpPort = 8096;
  radarrPort = 31834;
  sonarrPort = 19453;
  readarrPort = 38813;
  prowlarrPort = 38137;
  bazarrPort = 43816;
  qbittorrentPort = 47328;
in {
  services = {
    jellyfin = {
      enable = true;
    };
    radarr = {
      enable = true;
      settings = {
        server = {
          port = radarrPort;
        };
      };
    };
    sonarr = {
      enable = true;
      settings = {
        server = {
          port = sonarrPort;
        };
      };
    };
    readarr = {
      enable = true;
      settings = {
        server = {
          port = readarrPort;
        };
      };
    };
    bazarr = {
      enable = true;
      listenPort = prowlarrPort;
    };
    prowlarr = {
      enable = true;
      settings = {
        server = {
          port = prowlarrPort;
        };
      };
    };
    qbittorrent = {
      enable = true;
      webuiPort = qbittorrentPort;
    };
  };
  reverseProxy = {
    domains = {
      "jellyfin.${config.networking.domain}" = {
        port = jellyfinHttpPort;
      };
      "sonarr.${config.networking.domain}" = {
        port = sonarrPort;
      };
      "radarr.${config.networking.domain}" = {
        port = radarrPort;
      };
      "readarr.${config.networking.domain}" = {
        port = readarrPort;
      };
      "bazarr.${config.networking.domain}" = {
        port = bazarrPort;
      };
      "prowlarr.${config.networking.domain}" = {
        port = prowlarrPort;
      };
      "qbittorrent.${config.networking.domain}" = {
        port = qbittorrentPort;
      };
    };
  };
}
