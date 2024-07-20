{ lib, pkgs, ... }: let
  # disko = import ./disko.nix;
  # partitions = {
  #   boot = "${disk}-part1";
  #   btrfs = "${disk}-part2";
  # };
  # partitions = import ./partitions.nix;
  # subvolumes = disko.disko.devices.disk.vdb.content.partitions.luks.content.content.subvolumes;
in {
  nixpkgs = {
    hostPlatform = lib.mkForce "x86_64-linux";
  };
  services = {
    blueman = {
      enable = true;
    };
    thermald = {
      enable = true;
    };
    upower = {
      enable = true;
    };
  };
  environment = {
    systemPackages = with pkgs; [ glxinfo gnome.gnome-power-manager ];
  };
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
    opengl = {
      enable = true;
      # TODO: test
    };
  };

  networking = {
    hostName = "laptop";
    hostId = "bb0a37fd";
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
      luks = {
        devices = {
          crypted = {
            # device = partitions.luks;
          };
        };
      };
    };
    supportedFilesystems = [ "btrfs" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
	device = "nodev";
	efiSupport = true;
      };
      # systemd-boot = {
      #   enable = true;
      # };
    };
  };

  console = {
    enable = true;
  };

  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTg9IazPIM98HvEOp+nlUs3Rp7C4JOKA9GbmXl1UbW8 root@laptop";

  # wifi = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
