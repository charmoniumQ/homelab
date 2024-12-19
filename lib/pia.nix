/*
 * Adapted from https://git.sr.ht/~rprospero/nixos-pia/tree/development
 *
 * And therefore, this file is also licensed AGPLv3.
 */
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      openvpn = {
        servers = let
          resources = pkgs.fetchzip {
            name = "pia-vpn-config";
            url = "https://www.privateinternetaccess.com/openvpn/openvpn.zip";
            hash = "sha256-ZA8RS6eIjMVQfBt+9hYyhaq8LByy5oJaO9Ed+x8KtW8=";
            stripRoot = false;
          };
          fixup = (builtins.replaceStrings [ ".ovpn" "_" ] [ "" "-" ]);
          servers =
            (builtins.filter (name: !(isNull (builtins.match ".+ovpn$" name)))
              (builtins.attrNames (builtins.readDir resources)));
          make_server = (name: {
            name = fixup name;
            value = {
              autoStart = false;
              config = "config ${resources}/${name}\nauth-user-pass ${config.services.pia.authUserPassFile}";
              updateResolvConf = true;
            };
          });
        in builtins.listToAttrs (map make_server servers);
      };
    };
  };
  options = {
    services = {
      pia = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        authUserPassFile = lib.mkOption {
          type = lib.types.path;
          description = "Username, newline, password, newline";
        };
      };
    };
  };
}
