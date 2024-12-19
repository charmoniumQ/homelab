{ lib, pkgs, ... }:
{
  config = {
    environment = {
      systemPackages = [
        # If things go sideways, we wouldn't even be able to resolve Nix packages, so let's just pre-install a DNS debugging tool, `drill`.
        pkgs.ldns
        pkgs.dig.dnsutils
      ];
    };
  };
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
        type = lib.types.listOf (lib.types.strMatching "[a-z0-9][a-z0-9.-]+[a-z0-9]");
        description = "Additional DNS names to route to this host";
        default = [ ];
      };
    };
  };
}
