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
  imports =
    [ ./agenix.nix
      ./automatic-maintenance.nix
      ./caddy.nix
      ./dns.nix
      ./grafana
      ./loki.nix
      ./networked-node.nix
      ./nextcloud.nix
      ./nix-conf.nix
      ./runtime-tests.nix
      ./prometheus.nix
      ./promtail.nix
      ./reverse-proxy.nix
      ./ssh.nix
      ./sysadmin-user.nix
      ./unbound.nix
      ./zfs.nix
    ];
}
