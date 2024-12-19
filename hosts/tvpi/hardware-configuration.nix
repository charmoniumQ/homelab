{ modulesPath, lib, ... }: {
  # See https://wiki.nixos.org/wiki/NixOS_on_ARM/Initial_Configuration
  # https://blog.krishu.moe/posts/nixos-raspberry-pi/
  # boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi4;
  # boot.supportedFilesystems = lib.mkForce [ "vfat" "btrfs" "tmpfs" ];

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # NixOS wants to enable GRUB by default
  boot = {
    loader = {
      grub = {
        enable = false;
      };
      # Enables the generation of /boot/extlinux/extlinux.conf
      generic-extlinux-compatible = {
        enable = true;
      };
    };
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-linux";
  };

  fileSystems = {
    "/" = {
      device = lib.mkForce "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024 /* in MiB */;
    }
  ];

  networking = {
    hostName = "tvpi";
    networkmanager = {
      enable = true;
    };
  };

  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILI9nxtxR/WJPuGm3DdbcWm+UFO1ICtGvFe341QBic3G root@tvpi";

  wifi = true;

  system = {
    stateVersion = "24.05";
  };
}
