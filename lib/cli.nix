{ pkgs, ... }: {
  environment = {
    systemPackages = [
      pkgs.at

      # essential to already have in case you run out of disk space (and can't do nix shell)
      pkgs.gdu
    ];
  };
}
