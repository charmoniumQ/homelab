{ config, lib, ... }:
let
  types = {
    domain = (import ../nixlib/domain-name.nix) lib;
    urlPath = (import ../nixlib/url-path.nix) lib;
    email = (import ../nixlib/email.nix) lib;
  };
in {
  config = {
    networking = {
      firewall = {
        allowedTCPPorts = [ 80 443 ];
      };
    };
  };
  imports = [
    ./reverse-proxy/caddy.nix
    ./reverse-proxy/crowdsec.nix
  ];
  options = {
    endOptions = {
      webmasterEmail = lib.mkOption {
        type = types.email;
      };
    };
    paas = {
      reverseProxy = {
        provider = lib.mkOption {
          type = lib.types.enum [ "caddy" ];
          default = "caddy";
        };
        domains = lib.mkOption {
          description = "Set a reverse proxy from https://{reverse-proxy.{name}} to http://{reverse-proxy.{name}.host}:{reverse-proxy.{name}.port}";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              phpFastCgi = lib.mkOption {
                default = null;
                type = lib.types.nullOr (lib.types.submodule (attrs: {
                  options = {
                    phpRoot = lib.mkOption {
                      type = lib.types.path;
                      description = "Run PHP files from this path";
                    };
                    staticRoot = lib.mkOption {
                      type = lib.types.path;
                      default = attrs.config.phpRoot;
                      description = "Serve static files from this path";
                    };
                    socket = lib.mkOption {
                      type = lib.types.path;
                    };
                  };
                }));
              };
              reverseProxy = lib.mkOption {
                default = null;
                type = lib.types.nullOr (lib.types.submodule {
                  options = {
                    upstream = lib.mkOption {
                      type = types.domain;
                      default = "localhost";
                    };
                    port = lib.mkOption {
                      type = lib.types.port;
                    };
                  };
                });
              };
              redirectPaths = lib.mkOption {
                default = { };
                type = lib.types.listOf (lib.types.submodule ({name, ...}: {
                  options = {
                    from = lib.mkOption {
                      type = types.urlPath;
                      default = name;
                    };
                    to = lib.mkOption {
                      type = types.urlPath;
                    };
                    httpCode = lib.mkOption {
                      type = (lib.numbers.between 300 401);
                    };
                  };
                }));
              };
              forbidPaths = lib.mkOption {
                default = { };
                type = lib.types.listOf (lib.types.submodule ({name, ...}: {
                  options = {
                    path = lib.mkOption {
                      type = types.urlPath;
                      default = name;
                    };
                    httpCode = lib.mkOption {
                      type = (lib.numbers.between 300 401);
                    };
                  };
                }));
              };
              immutablePaths = lib.mkOption {
                default = { };
                type = lib.types.listOf (lib.types.submodule ({name, ...}: {
                  options = {
                    path = lib.mkOption {
                      type = types.urlPath;
                      default = name;
                    };
                  };
                }));
              };
              internalOnly = lib.mkOption {
                type = lib.types.bool;
                description = "Whether or not too accept connections on the WAN.";
                default = false;
              };
            };
          });
        };
      };
    };
  };
}
