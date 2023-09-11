{ pkgs, lib, config, ... }:
{
  config = {
    environment = {
      systemPackages = [
        # If things go sideways, we wouldn't even be able to resolve Nix packages, so let's just pre-install a DNS debugging tool, `drill`.
        pkgs.ldns
      ];
    };
    services = {
      unbound = {
        enable = true;
        settings = {
          server = {
            # Serve stale data if not older than 1 day
            # serve-expired = "yes";
            # serve-expired-ttl = 86400;
            # serve-expired-client-timeout = 1800;  # 1.8 seconds, in milliseconds
            interface = "0.0.0.0";
            access-control = [
              "192.168.0.0/16 allow"
              "172.16.0.0/12 allow"
              "10.0.0.0/8 allow"
              "127.0.0.1/8 allow"
              "fd00::/8 allow"
              "::1 allow"
            ];
            # TODO: parameterize
            # https://avoidthehack.com/best-pihole-blocklists
            # https://github.com/hagezi/dns-blocklists
            # https://github.com/lightswitch05/hosts
            # https://firebog.net/
            # include = builtins.toString (pkgs.fetchurl {
            #   url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=127.0.0.1";
            #   hash = "sha256-4qEOK/NUghXGR/ozmTOPzjNXlReEzQufMmQHBmepr9o=";
            # });
            tls-system-cert = true;
          } // (lib.attrsets.optionalAttrs ((config.reverseProxy.domains) != {}) {
            local-zone = builtins.map
              (domain: "\"${domain}.\" transparent\n")
              config.dns.localDomains
            ;
            local-data = builtins.map
              (domain: "\"${domain}. IN A ${config.localIP}\"\n")
              config.dns.localDomains
            ;
          });
          forward-zone = [
            {
              name = ".";
              forward-addr = config.dns.servers;
              forward-tls-upstream = true;
            }
          ];
        };
        enableRootTrustAnchor = true; # Enable DNSSEC
        # TODO: test DNSSEC
      };
    };
    networking = {
      nameservers = [ "127.0.0.1" ];
      firewall = {
        allowedUDPPorts = [ 53 ];
      };
    };
  };
}
