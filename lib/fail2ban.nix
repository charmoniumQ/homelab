{ lib, config, ...}: {
  config = {
    services = {
      fail2ban = {
        enable = true;
        ignoreIP = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "127.0.0.1/16"
        ];
        daemonSettings = {
          Definition = {
            loglevel = "WARNING";
            logtarget = "SYSTEMD-JOURNAL";
            socket = "/run/fail2ban/fail2ban.sock";
            pidfile = "/run/fail2ban/fail2ban.pid";
            dbfile = "/var/lib/fail2ban/fail2ban.sqlite3";
          };
        };
        jails = {
          caddy-status = {
            settings = {
              port = "http,https";
              filter = "caddy-status";
              logpath = "/var/log/caddy/*.access.log";
              maxretry = 10;
            };
          };
        };
      };
    };
    environment = lib.attrsets.optionalAttrs config.services.caddy.enable {
      etc = {
        "/etc/fail2ban/filter.d/caddy-status.conf" = {
          # https://muetsch.io/how-to-integrate-caddy-with-fail2ban.html
          text = ''
            [Definition]
            failregex = ^.*"remote_ip":"<HOST>",.*?"status":(?:401|403),.*$
            ignoreregex =
            datepattern = LongEpoch
          '';
        };
      };
    };
  };
}
