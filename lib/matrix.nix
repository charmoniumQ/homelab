{config, pkgs, lib, ...}:
let
  base-domain = "${config.networking.domain}";
  server-config = {
    "m.server" = "${base-domain}:443";
  };
  matrix-domain = "matrix.${base-domain}";
  port = lib.trace "Put this in a hash" 57261;
  element-domain = "element.${base-domain}";
  element-webroot = pkgs.element-web.override {
    conf = {
      default_server_config = server-config;
      default_server_name = matrix-domain;
    };
  };
in {
  services = {
    matrix-synapse = {
      enable = true;
      extras = [
        "oidc"
        "postgres"
        "systemd"
        "url-preview"
      ];
      settings = {
        server_name = base-domain;
        public_baseurl = "https://${matrix-domain}";
        enable_registration = false;
        database = {
          name = "psycopg2";
        };
        listeners = [
          {
            port = port;
            bind_addresses = [ "::1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [ "client" "federation" ];
                compress = true;
              }
            ];
          }
        ];
        oidc_providers = [
          {
            idp_id = "keycloak";
            idp_name = "SSO";
            issuer = "https://keycloak.samgrayson.me/realms/home";
            client_id = "synapse";
            client_secret = "dExxiSWUrx147ttWv7M90wh8ZNOd151K";
            scopes = ["openid" "profile"];
            user_mapping_provider = {
              config = {
                localpart_template = "{{ user.preferred_username }}";
                display_name_template = "{{ user.name }}";
              };
            };
            backchannel_logout_enabled = true;
            update_profile_information = true;
          }
        ];
      };
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "matrix-synapse" ];
      ensureUsers = [
        {
          name = "matrix-synapse";
          ensureDBOwnership = true;
        }
      ];
    };
    caddy = {
      virtualHosts = {
        "${matrix-domain}" = {
          extraConfig = ''
            reverse_proxy /_matrix/* localhost:${builtins.toString port}
            reverse_proxy /_synapse/client/* localhost:${builtins.toString port}
          '';
        };
        "${element-domain}" = {
          extraConfig = ''
            root * ${element-webroot}
            file_server
          '';
        };
      };
    };
    # coturn = rec {
    #   enable = true;
    #   no-cli = true;
    #   no-tcp-relay = true;
    #   min-port = 49000;
    #   max-port = 50000;
    #   use-auth-secret = true;
    #   static-auth-secret = "will be world readable for local users :(";
    #   realm = "turn.example.com";
    #   cert = "${config.security.acme.certs.${realm}.directory}/full.pem";
    #   pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";
    #   extraConfig = ''
    #     # for debugging
    #     verbose
    #     # ban private IP ranges
    #     no-multicast-peers
    #     denied-peer-ip=0.0.0.0-0.255.255.255
    #     denied-peer-ip=10.0.0.0-10.255.255.255
    #     denied-peer-ip=100.64.0.0-100.127.255.255
    #     denied-peer-ip=127.0.0.0-127.255.255.255
    #     denied-peer-ip=169.254.0.0-169.254.255.255
    #     denied-peer-ip=172.16.0.0-172.31.255.255
    #     denied-peer-ip=192.0.0.0-192.0.0.255
    #     denied-peer-ip=192.0.2.0-192.0.2.255
    #     denied-peer-ip=192.88.99.0-192.88.99.255
    #     denied-peer-ip=192.168.0.0-192.168.255.255
    #     denied-peer-ip=198.18.0.0-198.19.255.255
    #     denied-peer-ip=198.51.100.0-198.51.100.255
    #     denied-peer-ip=203.0.113.0-203.0.113.255
    #     denied-peer-ip=240.0.0.0-255.255.255.255
    #     denied-peer-ip=::1
    #     denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
    #     denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
    #     denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
    #     denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
    #     denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #     denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #     denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #   '';
    # };
  };
  # networking = {
  #     firewall = {
  #       interfaces = {
  #         enp2s0 = let
  #           range = with config.services.coturn; [ {
  #             from = min-port;
  #             to = max-port;
  #           } ];
  #         in {
  #           allowedUDPPortRanges = range;
  #           allowedUDPPorts = [ 3478 5349 ];
  #           allowedTCPPortRanges = [ ];
  #           allowedTCPPorts = [ 3478 5349 ];
  #         };
  #       };
  #     };
  #   };
  # };
  # get a certificate
  # security = {
  #   acme = {
  #     certs = {
  #       ${config.services.coturn.realm} = {
  #         /* insert here the right configuration to obtain a certificate */
  #         postRun = "systemctl restart coturn.service";
  #         group = "turnserver";
  #       };
  #     };
  #   };
  # };
}
