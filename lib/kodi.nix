{ pkgs, ... }: {
  environment = {
    systemPackages = [
      (pkgs.kodi-wayland.passthru.withPackages (kodiPkgs: with kodiPkgs; [
		    youtube
	    ]))
    ];
  };
}
