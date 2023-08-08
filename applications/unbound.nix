{ pkgs, ... }:
{
  services = {
    unbound = {
      enable = true;
      settings = {
        server = {
          # Serve stale data if not older than 1 day
          serve-expired = "yes";
          serve-expired-ttl = 86400;
          serve-expired-client-timeout = 1800;  # 1.8 seconds, in milliseconds
          interface = "0.0.0.0";
          access-control = [
            "127.0.0.0/8 allow"
            "10.0.0.0/8 allow" # TODO: restrict to local subnet
          ];
          # TODO: parameterize
          # https://firebog.net/
          include = builtins.toString (pkgs.fetchurl {
            url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=127.0.0.1";
            hash = "sha256-4qEOK/NUghXGR/ozmTOPzjNXlReEzQufMmQHBmepr9o=";
          });
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com" # TODO: parametrize
            ];
          }
        ];
        # TODO: scrape these from configs
        local-zone = [
          "nextcloud.samgrayson.me static"
          "alertmanager.samgrayson.me static"
          "prometheus.samgrayson.me static"
        ];
        local-data = [
          "nextcloud.samgrayson.me A 10.0.0.12"
          "alertmanager.samgrayson.me A 10.0.0.12"
          "prometheus.samgrayson.me A 10.0.0.12"
        ];
      };
      enableRootTrustAnchor = true; # Enable DNSSEC
      # TODO: test DNSSEC
    };
  };
}
