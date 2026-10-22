{ pkgs, sops-nix, ...}: {
  imports = [
    sops-nix.nixosModules.sops
  ];
  sops = {
    # package =
    #   sops-nix.packages."x86-64".sops-install-secrets.overrideAttrs
    #     {
    #       postInstall = "";
    #       outputs = [ "out" ];
    #       enableParallelBuilding = false;
    #       enableParallelChecking = false;
    #       enableParallelInstalling = false;
    #     };
    defaultSopsFile = ../secrets/all.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };
}
