{ disks
  ? [
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00BBHA0_WD-WCC6Y2XC5S4R"
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y1FZ1NTR"
  ],
  sizes
  ? {
    swap = "32G";
    bpool = "4G";
    esp = "1G";
    reserve = "1G";
  },
  lib,
  ...
}:
let
  zipRange = lst: lib.lists.zipListsWith (diskNo: disk: {inherit disk diskNo;}) (lib.lists.range 0 ((builtins.length lst) - 1)) lst;
in
{
  disko = {
    # https://github.com/nix-community/disko/blob/493b347d8fffa6912afb8d89b91703cd40ff6038/lib/default.nix#L330
    devices = {
      disk = builtins.listToAttrs (builtins.map ({disk, diskNo}:
        {
          name = disk;
          value = {
            # https://github.com/nix-community/disko/blob/master/lib/types/disk.nix
            type = "disk";
            device = disk;
            content = {
              # https://github.com/nix-community/disko/blob/master/lib/types/gpt.nix
              type = "gpt";
              partitions = {
                BIOS = {
                  start = "1MiB";
                  end = "2MiB";
                  type = "EF02";
                  content = {
                    # https://github.com/nix-community/disko/blob/master/lib/types/filesystem.nix
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot/${builtins.toString diskNo}";
                  };
                };
                ESP = {
                  start = "0";
                  size = "${sizes.esp}";
                  type = "EF00";
                  content = {
                    # https://github.com/nix-community/disko/blob/master/lib/types/filesystem.nix
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot/efi/${builtins.toString diskNo}";
                  };
                };
                swap = {
                  start = "0";
                  size = "${sizes.swap}";
                };
                bpool = {
                  start = "0";
                  size = "${sizes.bpool}";
                  type = "bf01";
                  content = {
                    type = "zfs";
                    pool = "bpool";
                  };
                };
                rpool = {
                  start = "0";
                  end = "-${sizes.reserve}";
                  type = "bf01";
                  content = {
                    type = "zfs";
                    pool = "rpool";
                  };
                };
                datasets = {};
              };
            };
          };
        }) (zipRange disks));
      # https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/Root%20on%20ZFS.html
      zpool = {
        # https://github.com/nix-community/disko/tree/master/lib/types/zpool.nix
        bpool = {
          type = "zpool";
          mode = "mirror";
          options = {
            compatibility = "grub2";
            ashift = "12";
            autotrim = "on";
          };
          rootFsOptions = {
            acltype = "posixacl";
            compression = "on";
            devices = "off";
            normalization = "formD";
            relatime = "on";
            xattr = "sa";
            mountpoint = "legacy";
          };
          mountpoint = "/boot";
          datasets = {};
        };
        rpool = {
          type = "zpool";
          mode = "mirror";
          options = {
            ashift = "12";
            autotrim = "on";
          };
          rootFsOptions = {
            acltype = "posixacl";
            compression = "on";
            dnodesize = "auto";
            normalization = "formD";
            relatime = "on";
            xattr = "sa";
            mountpoint = "legacy";
          };
          mountpoint = "/";
          datasets = {};
        };
      };
    };
  };
}
