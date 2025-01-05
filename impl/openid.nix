{ lib, ... }: {
  imports = [
    ./openid/keycloak.nix
  ];
  options = {
    endOptions = {
      openid = {
        provider = lib.mkOption {
          type = lib.enum [ "keycloak" ];
          default = "keycloak";
        };
      };
    };
  };
}
