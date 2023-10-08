{ config, lib, pkgs, ... }:
let
  cfg = config.externalSmtp;
  jsonCfg = (pkgs.formats.json {}).generate "cfg.json" cfg;
  python_ = pkgs.python311.withPackages (pypkgs: [ pypkgs.retry ]);
  python = "${python_}/bin/python";
  script = pkgs.writeText "script.py" (builtins.readFile ./externalSmtp.py);
in {
  config = {
    runtimeTests = {
      tests = lib.attrsets.optionalAttrs cfg.enable {
        "external-smtp-test" = {
          script = "${python} ${script} ${jsonCfg}";
          date = "daily";
          after = [ "network-online.target" ];
        };
      };
    };
  };
  options = {
    externalSmtp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to allow this server to send emails to users using the specified SMTP server.";
      };
      host = lib.mkOption {
        type = lib.types.strMatching "[a-z0-9.-]+";
        description = "Hostname of SMTP server to use.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port of SMTP server to use.";
      };
      security = lib.mkOption {
        type = lib.types.enum [ "" "ssl" "starttls" ];
        description = "Security protocl used to access SMTP server.";
      };
      authentication = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this SMTP server requires authentication.";
      };
      username = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Username with which to log in to the SMTP server. Defaults to \${fromUser}@\${fromDomain}";
        default = "${cfg.fromUser}@${cfg.fromDomain}";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "File containing the password with which to log in to the SMTP server.";
      };
      fromUser = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "The user-half of the \"from\" email address.";
      };
      fromDomain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "The domain-half of the \"from\" email address to use.";
      };
    };
  };
}
