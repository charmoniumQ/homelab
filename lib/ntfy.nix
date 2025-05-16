{ config, ... }:
let
  port = 34287;
  base-url = "ntfy.${config.networking.domain}";
in {
  services = {
    ntfy-sh = {
      enable = true;
      settings = {
        listen-http = "localhost:${builtins.toString port}";
        base-url = "https://${base-url}";
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";
        cache-file = "/var/lib/ntfy-sh/cache.db";
        cache-duration = "24h";
        enable-signup = false;
        enable-login = true;
      };
    };
  };
  reverseProxy = {
    domains = {
      "${base-url}" = {
        port = port;
      };
    };
  };
}
