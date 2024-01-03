/*
Configures NixOS system updates, Nixpkgs channel, and Nix command.
*/
{ pkgs, lib, self, config, ... }:
{
  config = {
    system = {
      stateVersion = "23.11";
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
      package = pkgs.nixUnstable;
      channel = {
        enable = true;
      };
      settings = {
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org/"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        experimental-features = [ "nix-command" "flakes" ];
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
      ];
    };
  };
}
