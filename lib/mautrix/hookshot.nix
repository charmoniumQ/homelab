{ config, ... }:
let
  homeserverPort = 57261;
  hookshotPort = 43789;
  webhookPort = 56253;
in {
  services = {
    matrix-hookshot = {
      enable = true;
      settings = {
        bridge = {
          domain = config.networking.domain; # The homeserver's server name.
          url = "http://localhost:${builtins.toString homeserverPort}"; # The URL where Hookshot can reach the client-server API.
          mediaUrl = "https://hookshot.matrix.${config.networking.domain}"; # Optional. The url where media hosted on the homeserver is reachable (this should be publically reachable from the internet)
          port = hookshotPort; # The port where hookshot will listen for appservice requests.
          bindAddress = "127.0.0.1"; # The address which Hookshot will bind to. Docker users should set this to `0.0.0.0`.
        };
        permissions = [
          {
            actor = "@admin:samgrayson.me";
            services = [
              {
                service = "*";
                level = "admin";
              }
            ];
          }
          {
            actor = "samgrayson.me";
            services = [
              {
                service = "*";
                level = "manageConnections";
              }
            ];
          }
        ];
        listeners = [
          # (Optional) HTTP Listener configuration.
          # Bind resource endpoints to ports and addresses.
          # 'resources' may be any of webhooks, widgets, metrics, provisioning
          {
            port = webhookPort;
            bindAddress = "0.0.0.0";
            resources = [
              "webhooks"
            ];
          }
        ];
      };
    };
  };
  reverseProxy = {
    domains = {
      "hookshot.matrix.${config.networking.domain}" = {
        port = hookshotPort;
      };
      "webooks.hookshot.matrix.${config.networking.domain}" = {
        port = webhookPort;
      };
    };
  };
}
