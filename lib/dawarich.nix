{ config, ... }: {
  config = {
    services = {
      dawarich = {
        enable = true;
        webPort = 3861;
        localDomain = "dawarich.samgrayson.me";
        configureNginx = false;
        smtp = {
          host = config.externalSmtp.host;
          port = config.externalSmtp.port;
          user = config.externalSmtp.username;
          passwordFile = config.externalSmtp.passwordFile;
        };
      };
    };
    reverseProxy = {
      domains = {
        "${config.services.dawarich.localDomain}" = {
          port = config.services.dawarich.webPort;
          extraProxyConfig = ''
            encode brotli {
		          match {
			          content_type
                  text/css
                  text/plain
                  text/xml
                  text/x-component
                  text/javascript
                  application/x-javascript
                  application/javascript
                  application/json
                  application/manifest+json
                  application/vnd.api+json
                  application/xml
                  application/xhtml+xml
                  application/rss+xml
                  application/atom+xml
                  application/vnd.ms-fontobject
                  application/x-font-ttf
                  application/x-font-opentype
                  application/x-font-truetype
                  image/svg+xml
                  image/x-icon
                  image/vnd.microsoft.icon
                  font/ttf
                  font/eot
                  font/otf
                  font/opentype
		          }
	          }
          '';
        };
      };
    };
  };
}
