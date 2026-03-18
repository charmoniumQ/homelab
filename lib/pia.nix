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
          resources = let
            original = pkgs.fetchzip {
              name = "pia-vpn-config";
              url = "https://www.privateinternetaccess.com/openvpn/openvpn.zip";
              hash = "sha256-mhXV2CF8G7dAkXY9KI7g2qSOlxUzyqgJlidL1At46GU=";
              stripRoot = false;
            };
          in
            pkgs.runCommand "modified" {} ''
              cp ${original}/*.ovpn .
              sed --in-place '/<crl-verify>/,/<\/crl-verify>/d' *.ovpn
              mkdir $out
              cp *.ovpn $out
            '';
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
