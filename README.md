# Sam's Homelab

It's mine, and it's awesome.

## To configure

1. [NixOS](https://nixos.org/manual/nixos/unstable/options) provides basic options for most packages.
2. Modules in [`./lib/*.nix`](./lib/default.nix) provide opinionated defaults and new option interfaces.
   - For an example of opinionated defaults, if `services.nextcloud.enabled` is set to true, this `./lib/nextcloud.nix` will expose create reverse proxy from `https://nextcloud.${networking.domain}` to the Nextcloud PHP FastCGI server.
   - For an example of new option interfaces, the user can set language, country code, currency, and units in a `config.locale.*` (see [`./lib/locale.nix`](./lib/locale.nix)) which get used by the aforementioned "opinionated defaults" in this libary.
3. Site-specific customization takes place in [`hosts/site.nix`](./hosts/site.nix); this applies to the whole network.
4. Host-specific customization takes place in [`hosts/*/default.nix`](./hosts/home-server/default.nix), which applies only to one node.
5. Secrets are encrypted by [Agenix](https://github.com/ryantm/agenix), declared in [`./secrets/secrets.nix`](./secrets/secrets.nix), and stored in [`./secrets/*.age`](./secrets/). They are encrypted with the sysadmin's SSH public key and the server's SSH host public key, such that they are write/read-able with either of the associated private keys.

## To deploy

1. Optionally type-check with `nix flake check --show-trace`
2. Actually apply with [colmena](https://github.com/zhaofengli/colmena): `nix develop --command colmena apply`.

Note, you can optionally, build a QEMU VM image with `nix build .home-server-qemu`

## Setting up Nextcloud <-> CalDAV <-> Android

1. Download F-Droid
2. In F-Droid, download "Nextcloud Sync" and "Dav5x"
3. Log in to Nextcloud Sync
4. In the Nextcloud mobile, go to Settings/More, tap on “Sync calendars & contacts”.
5. Follow this flow, which will have you logging in to Nextcloud again
6. Set Contact Group Method to Groups are per-contact categories.
7. launch DAVx⁵ again.

See also [Nextcloud manual](https://docs.nextcloud.com/server/latest/user_manual/en/groupware/sync_android.html#contacts-and-calendar)
