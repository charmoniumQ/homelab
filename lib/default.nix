/*

The point of this library is to simplify deploying and customizing
common services.

Options that the user will likely need to change (especially when
deploying to a new site) should be set in site- or host-specific
configuration. However, defaults may still be set here.

Options that the user will likely not need to change will be set here.

TODO: isolate out the "interface" modules from the "implementation" modules
Also isolate out the "heavily customized implementation" components (nextcloud.extraApps, Grafana dashboards, homre-manager config and dashboards)

 */

{ config, ... }:
{
  imports = [
    ./agenix.nix
    ./automaticMaintenance.nix
    ./backups.nix
    ./caddy.nix
    ./dns.nix
    ./dyndns.nix
    ./externalSmtp.nix
    ./fail2ban.nix
    ./generatedFiles.nix
    ./grafana.nix
    ./home-assistant.nix
    ./locale.nix
    ./loki.nix
    ./networkedNode.nix
    ./nextcloud.nix
    ./nixConf.nix
    ./runtimeTests.nix
    ./prometheus.nix
    ./promtail.nix
    ./reverseProxy.nix
    ./ssh.nix
    ./sysadmin.nix
    ./vaultwarden.nix
    ./unbound.nix
    ./zfs.nix
  ];
}
