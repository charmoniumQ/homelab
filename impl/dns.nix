{ lib, ... }: let
  domainNameType = (import ../nixlib/domain-name.nix) lib;
in {
  options = {
    endOptions = {
      # admonition here:
      # https://www.reddit.com/r/selfhosted/comments/10blkx0/moving_dns_hosting_from_namecheap_registrar_to_my/
      # I guess I just shouldn't use Bind
      dns = {
        defaultApex = lib.mkOption {
          type = domainNameType;
        };
        provider = lib.mkOption {
          type = lib.types.enum [ "authoritative-ns" ];
          default = "authoritative-ns";
        };
      };
    };
  };
}
