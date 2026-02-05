/*
Configures NixOS system updates, Nixpkgs channel, and Nix command.
*/
{ system, pkgs, lib, self, config, nix-alien, ... }:
{
  config = {
    programs = {
      nix-ld = {
        enable = true;
      };
    };
    system = {
      # TODO: enable
      autoUpgrade = {
        enable = false;
        allowReboot = config.automaticMaintenance.enable;
        dates = config.automaticMaintenance.weeklyTime;
        persistent = true;
        randomizedDelaySec = config.automaticMaintenance.randomizedDelay;
        flake = self.outPath;
        flags = [
          "--update-input"
          "nixpkgs"
          "-L" # print build logs
        ];
      };
    };
    nix = {
      enable = true;
      package = pkgs.nixVersions.latest;
      channel = {
        enable = false;
      };
      settings = {
        use-xdg-base-directories = true;
        substituters = [
          "https://hydra.lordofthelags.net"
          "https://nix-community.cachix.org"
          "https://cache.nixos.org/"
          # "https://cache.flox.dev"
          "https://selfhostblocks.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          # "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          "selfhostblocks.cachix.org-1:H5h6Uj188DObUJDbEbSAwc377uvcjSFOfpxyCFP7cVs="
          "hydra.lordofthelags.net:v3OFf3HWmShqFqJIYCBRDVGpFxyq9Pc8QMflK8hcOYE="
        ];
        experimental-features = [ "nix-command" "flakes" ];
        extra-platforms = config.boot.binfmt.emulatedSystems ++ [ config.nixpkgs.hostPlatform.system ];
      };
      gc = {
        automatic = config.automaticMaintenance.enable;
        dates = config.automaticMaintenance.weeklyTime;
        persistent = true;
        randomizedDelaySec = config.automaticMaintenance.randomizedDelay;
        options = "--delete-older-than 8d";
      };
      optimise = {
        automatic = config.automaticMaintenance.enable;
        dates = [ (
          lib.trivial.warn
            "See if this can take randomizedDelay"
            config.automaticMaintenance.weeklyTime
        ) ];
      };
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    environment = {
      systemPackages = [
        pkgs.gitMinimal # Needed to make Nix flakes work
        nix-alien.packages.${config.nixpkgs.hostPlatform.system}.nix-alien
        pkgs.cachix
      ];
      etc = {
        "nix/system-packages.list" = {
          text = let
            packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
            sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
          in
            builtins.concatStringsSep "\n" sortedUnique
          ;
        };
      };
    };
  };
}
