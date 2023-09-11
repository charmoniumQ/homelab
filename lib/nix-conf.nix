/*
Configures NixOS system updates, Nixpkgs channel, and Nix command.
*/
{ pkgs, self, config, ... }:
{
  imports = [ ./automatic-maintenance.nix ];
  config = {
    system = {
      stateVersion = "23.11";
      # TODO: enable
      autoUpgrade = {
        enable = config.automaticMaintenance.enable;
        allowReboot = config.automaticMaintenance.enable;
        dates = config.automaticMaintenance.time;
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
        experimental-features = [ "nix-command" "flakes" ];
      };
      gc = {
        automatic = config.automaticMaintenance.enable;
        dates = config.automaticMaintenance.time;
      };
      optimise = {
        automatic = config.automaticMaintenance.enable;
        dates = [
          config.automaticMaintenance.time
        ];
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
