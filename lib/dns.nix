{ lib, ... }:
{
  options = {
    dns = {
      servers = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        description = "DNS servers to forward requests to";
        default = [
          "1.1.1.1@853#cloudflare-dns.com"
          "1.0.0.1@853#cloudflare-dns.com"
        ];
      };
      localDomains = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "[a-z0-9.-]+");
        description = "Additional DNS names to route to this host";
        default = [ ];
      };
    };
  };
}
