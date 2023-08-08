{ modulesPath, lib, pkgs, ... }:
let
  disks = [
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00BBHA0_WD-WCC6Y2XC5S4R"
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y1FZ1NTR"
  ];
  swapPart = "-part3";
  espPart = "-part2";
  zipRange = lst: lib.lists.zipListsWith (elemNo: elem: {inherit elem elemNo;}) (lib.lists.range 0 ((builtins.length lst) - 1)) lst;
in
{
  imports = [
    (modulesPath + "/profiles/headless.nix")
    # (modulesPath + "/profiles/qemu-guest.nix")
    # ./applications/unbound.nix
    # ./applications/ddclient.nix
    # ./applications/nextcloud.nix
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
      allowedTCPPorts = [ 22 80 443 ];
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
      efi = {
        canTouchEfiVariables = false;
	      efiSysMountPoint = "/boot/efis/0";
      };
      grub = {
        enable = true;
        devices = disks;
	      efiSupport = true;
	      zfsSupport = true;
      };
    };
  };
  fileSystems = {
    "/" = {
      device = "rpool";
      fsType = "zfs";
      options = [ "X-mount.mkdir" "noatime" ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "bpool";
      fsType = "zfs";
      options = [ "X-mount.mkdir" "noatime" ];
      neededForBoot = true;
    };
  }
  // (builtins.listToAttrs (builtins.map ({elem, elemNo}: {
    name = "/boot/efis/${builtins.toString elemNo}";
    value = {
      device = "${elem}${espPart}";
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
  }) (zipRange disks)));
  swapDevices = builtins.map (disk: {
    device = "${disk}${swapPart}";
  }) disks;
  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };
}
