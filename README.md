# Sam's Homelab

1. Customize [`hosts/site.nix`](./hosts/site.nix), [`hosts/*/default.nix`](./hosts/home-server/default.nix), and [`./lib/*`](./lib/default.nix).
2. Type-check with `nix flake check --show-trace`
2. Apply with `nix develop --command colmena apply` ([colmena](https://github.com/zhaofengli/colmena)).
