{
  imports = [
    ../../services/automatic-maintenance.nix
    ../../services/backups.nix
    ../../services/base.nix
    ../../services/ssh.nix
    ../../services/sysadminLogin.nix
    ../../services/tandoor.nix
    ../../services/zfs.nix
  ];

  endOptions = {
    webmasterEmail = "sam+acme@samgrayson.me";
    sysadmins = {
      sam = {
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5wkgmvprQC0v8p4UfmRDosFwqA8Sq4suRhLa/bC5YO JuiceSSH"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlV+zu9Fgj2Hsg7CIpoQxbPJTWxrasJ/Cy25Wg5pyxX sam@katherine-XPS-13-9350"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/7TzK2DDclyCe01RptAXD/p5aForn9V84iCzVeFmMw sam@laptop"
        ];
        hashedPassword = "$y$j9T$jHMH.J4FSjzEo9NpewkFR.$xNsebp97QdJPMMprorTPGar5KpKFd0EEzMhuFzkvN71";
      };
    };
    dns = {
      defaultApex = "samgrayson.me";
    };
  };

  # hardware
  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };
  system = {
    stateVersion = "25.05";
  };
}
