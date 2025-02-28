{ pkgs, ... }: {
  users = {
    users = {
      restricted-ssh-user = {
        isNormalUser = false;
        isSystemUser = true;
        group = "restricted";
        shell = let
          shell-pkg = pkgs.writeShellScriptBin "rbash-with-ssh" ''
            export PATH=${pkgs.openssh.out}/bin:${pkgs.coreutils.out}/bin
            exec ${pkgs.bashInteractive}/bin/bash --restricted
          '';
        in "${shell-pkg}/bin/rbash-with-ssh";
      };
    };
    groups = {
      restricted = { };
    };
  };
}
