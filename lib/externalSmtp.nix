{ config, lib, pkgs, ... }:
let
  cfg = config.externalSmtp;
  pyScript = ''
    import smtplib, pathlib
    security = "${cfg.security}"
    for _ in range(10):
      try:
        server = (smtplib.SMTP_SSL if security == "ssl" else smtplib.SMTP)("${cfg.host}", ${builtins.toString cfg.port})
      except Exception as exc:
        exc2 = exc
      else:
        exc2 = None
        break
    if exc2 is not None:
      raise exc2
    if security == "startls":
      server.starttls()
    server.login("${cfg.username}", pathlib.Path("${cfg.passwordFile}").read_text())
    server.ehlo_or_helo_if_needed()
    server.quit()
  '';
in {
  config = {
    runtimeTests = {
      tests = lib.attrsets.optionalAttrs cfg.enable {
        "externalSmtpTest" = {
          script = "${pkgs.python311}/bin/python ${builtins.toFile "externalSmtpTest.py" pyScript}";
          date = "daily";
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
