# Sam's Homelab

1. Customize [`hosts/site.nix`](./hosts/site.nix), [`hosts/*/default.nix`](./hosts/home-server/default.nix), and [`./lib/*`](./lib/default.nix).
2. Type-check with `nix flake check --show-trace`
2. Apply with `nix develop --command colmena apply` ([colmena](https://github.com/zhaofengli/colmena)).

## Setting up Nextcloud <-> CalDAV <-> Android

1. Download F-Droid
2. In F-Droid, download "Nextcloud Sync" and "Dav5x"
3. Log in to Nextcloud Sync
4. In the Nextcloud mobile, go to Settings/More, tap on “Sync calendars & contacts”.
5. Follow this flow, which will have you logging in to Nextcloud again
6. Set Contact Group Method to Groups are per-contact categories.
7. launch DAVx⁵ again.

See also [Nextcloud manual](https://docs.nextcloud.com/server/latest/user_manual/en/groupware/sync_android.html#contacts-and-calendar)
