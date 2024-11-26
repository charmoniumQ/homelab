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
      package = pkgs.nixVersions.git;
      channel = {
        enable = true;
      };
      settings = {
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org/"
          # "https://cache.flox.dev"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          # "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
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
      ];
    };
  };
}
