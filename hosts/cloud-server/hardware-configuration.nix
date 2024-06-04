{ lib, ... }:
{

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };

  # fileSystems = {
  #   "/boot/efi" = {
  #     device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_47255589-part15";
  #     fsType = "vfat";
  #   };
  #   "/" = {
  #     device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_47255589-part1";
  #     fsType = "ext4";
  #   };
  # };

  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-linux";
  };

  hardware = {
    enableAllFirmware = true;
  };

  networking = {
    hostName = "remote";
    hostId = "5204291d";
    networkmanager = {
      enable = true;
    };
    useDHCP = lib.mkDefault true;
    # interfaces.enp1s0.useDHCP = lib.mkDefault true;
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPortRanges = [
        {
          from = 60000;
          to = 61000;
        }
      ];
      enable = true;
    };
  };

  console = {
    enable = true;
  };

  services = {
    openssh = {
      enable = true;
    };
  };

  localIP = "49.13.239.201";
  wifi = false;
  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6wo8LKW1UqaCCradcCQq9xrKTAkr4Ln+VMhNos45M7 root@remote";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
