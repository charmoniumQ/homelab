/*
Configures NixOS system updates, Nixpkgs channel, and Nix command.
*/
{ pkgs, self, ... }:
{
  config = {
    system = {
      stateVersion = "23.11";
      # TODO: enable
      autoUpgrade = {
        enable = true;
        allowReboot = true;
        dates = "daily";
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
        automatic = true;
        dates = "weekly";
      };
      optimise = {
        automatic = true;
        dates = [
          "weekly"
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
