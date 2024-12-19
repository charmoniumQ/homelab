{ pkgs, ... }:
{
  services = {
    mopidy = {
      extensionPackages = let
        mopidyPackagesOverride = pkgs.mopidyPackages.overrideScope (prev: final: {
          extraPkgs = pkgs: [ pkgs.yt-dlp ];
        });
      in [
        mopidyPackagesOverride.mopidy-youtube
        mopidyPackagesOverride.mopidy-spotify
        mopidyPackagesOverride.mopidy-mopify
      ];
      configuration = ''
        [youtube]
        youtube_dl_package = yt_dlp
        # https://blog.pclewis.com/2016/03/20/mopidy-with-extensions-on-nixos.html
      '';
    };
  };
}
