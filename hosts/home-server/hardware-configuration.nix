/*
This module contains all and only information specific to one particular host.
Most of it comes from nixos-generate.
*/
{ config, lib, pkgs, ... }:
let
  # TODO: use by-uuid
  disks = [
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00BBHA0_WD-WCC6Y2XC5S4R"
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y1FZ1NTR"
  ];
  biosPart = "1";
  espPart = "2";
  swapPart = "3";
  bootPart = "4";
  tankPart = "5";
  mountpoints = [
    "/$"
    "/nix/var"
    "/nix/store"
    "/home"
    "/var"
    "/data"
  ];
  enumerate = lst: lib.lists.zipListsWith (elemNo: elem: {inherit elem elemNo;}) (lib.lists.range 0 ((builtins.length lst) - 1)) lst;
in
{

  services = {
    home-assistant = {
      zigbeeDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_e8f237a26645ed118378c68f0a86e0b4-if00-port0";
    };
    # dhcp-server = {
    #   interface = "enp4s0";
    # };
  };

  hardware = {
    enableAllFirmware = true;
    cpu = {
      amd = {
        updateMicrocode = true;
      };
    };
    graphics = {
      enable = true;
    };
    nvidia = {
      # https://nixos.wiki/wiki/Nvidia
      # Modesetting is required.
      modesetting.enable = true;

      # Whether to use the NVidia open source kernel module
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
	    # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # NVIDIA Corporation GT218 [GeForce 8400 GS Rev. 3] (rev a2)
      # https://www.nvidia.com/download/driverResults.aspx/89883/en-us/
      # https://nixos.wiki/wiki/Nvidia
      # package = config.boot.kernelPackages.nvidiaPackages.legacy_340;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
  networking = {
    hostName = "home-server";
    hostId = "0decdc86";
  };

  boot = {
    kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
    initrd = {
      availableKernelModules = [
        "ahci"
        "ohci_pci"
        "ehci_pci"
        "pata_atiixp"
        "xhci_pci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
    };
    loader = {
      timeout = 5;
      efi = {
        canTouchEfiVariables = false;
	      efiSysMountPoint = "/boot/efis/0";
      };
      # grub = {
      #   enable = false;
      # };
      # systemd-boot = {
      #   enable = true;
      # };
      grub = {
        enable = true;
        devices = disks;
	      efiSupport = true;
        efiInstallAsRemovable = true;
        zfsSupport = true;
        extraFiles = {
          "memtest.bin" = "${pkgs.memtest86plus}/memtest.bin";
        };
        memtest86 = {
          enable = true;
        };
      };
    };
  };

  console = {
    enable = true;
  };

  fileSystems = {
    "/boot" = {
      device = "bpool/boot";
      fsType = "zfs";
      neededForBoot = true;
    };
  }
  // (builtins.listToAttrs (builtins.map (mountpoint: {
    name = builtins.replaceStrings ["$"] [""] mountpoint;
    value = {
      device = "tank/${builtins.replaceStrings ["/" "$"] ["" "root"] mountpoint}";
      fsType = "zfs";
      neededForBoot = true;
    };
  }) mountpoints))
  // (builtins.listToAttrs (builtins.map ({elem, elemNo}: {
    name = "/boot/efis/${builtins.toString elemNo}";
    value = {
      device = "${elem}-part${espPart}";
      fsType = "vfat";
      options = [
        "x-systemd.idle-timeout=1min"
        "x-systemd.automount"
        "noauto"
        "nofail"
        "noatime"
        "X-mount.mkdir"
      ];
    };
  }) (enumerate disks)));

  swapDevices = builtins.map (disk: {
    device = "${disk}-part${swapPart}";
  }) disks;

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };
  localIP = "192.168.1.28";
  wifi = false;
  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2OwUfcZINCrf8UT5g3qgH5T4xhda56yx6+4EIzIX9h root@homeserver";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
