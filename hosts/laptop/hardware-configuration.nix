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
    hostPlatform = "x86_64-linux";
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
      driSupport = true;
      driSupport32Bit = true;
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

  # fileSystems = ((x: lib.debug.traceSeq x x) ({
  #   "/boot" = {
  #     device = partitions.boot;
  #     fsType = "vfat";
  #   };
  # } // (lib.attrsets.mapAttrs' (name: config: {
  #   name = config.mountpoint;
  #   value = {
  #     device = partitions.btrfs;
  #     fsType = "btrfs";
  #     options = [ "subvol=${name}" ] ++ config.mountOptions;
  #   } // lib.attrsets.optionalAttrs (name == "varlog") { neededForBoot = true; };
  # }) subvolumes)));

  # swapDevices = [ {
  #   device = "/swap/swapfile";
  # } ];
}
