/*

The point of this library is to simplify deploying and customizing
common services.

Options that the user will likely need to change (especially when
deploying to a new site) should be set in site- or host-specific
configuration. However, defaults may still be set here.

Options that the user will likely not need to change will be set here.

 */

{ config, ... }:
{
  imports = [
    ./agenix.nix
    ./automaticMaintenance.nix
    ./caddy.nix
    ./dns.nix
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
