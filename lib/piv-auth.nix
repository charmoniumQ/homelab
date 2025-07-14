{ pkgs, ... }: {
  environment = {
    systemPackages = [
      pkgs.opensc
      pkgs.pcsclite
      pkgs.pcsc-tools
      pkgs.ccid
      pkgs.yubikey-manager
    ];
  };
  services = {
    pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };
  };
}
