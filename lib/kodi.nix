{ pkgs, ... }: {
  environment = {
    systemPackages = [
      (pkgs.kodi-wayland.passthru.withPackages (kodiPkgs: with kodiPkgs; [
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/kodi-packages.nix
        youtube
        jellycon
      ]))
    ];
  };
}
