{ config, modulesPath, lib, pkgs, ... }:
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
  imports = [
    (modulesPath + "/profiles/headless.nix")
    # (modulesPath + "/profiles/qemu-guest.nix")
    ../../applications/reverse-proxy.nix
    # ../../applications/log-collection.nix
    # ../../applications/log-storage.nix
    # ../../applications/unbound.nix
    # ../../applications/ddclient.nix
    # ../../applications/nextcloud.nix
  ];
  hardware = {
    enableAllFirmware = true;
    cpu = {
      amd = {
        updateMicrocode = true;
      };
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      # TODO: test opengl and vulkan
    };
    nvidia = {
      nvidiaSettings = true;
    };
  };
  networking = {
    hostName = "homeserver";
    hostId = "0decdc86";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
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


  /* Testing */
  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.local.samgrayson.me";
        http_port = 2342;
        http_addr = "127.0.0.1";
      };
    };
  };
  reverseProxy = {
    domains = {
      ":2000" = {
        host = config.services.grafana.settings.server.http_addr;
        port = config.services.grafana.settings.server.http_port;
      };
    };
  };
}
