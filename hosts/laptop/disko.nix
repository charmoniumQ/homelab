{ ... }: {
  disko = {
    enableConfig = true;
    devices = {
      disk = {
        vdb = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_500GB_224448800320";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "600M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "defaults"
                  ];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  passwordFile = "/tmp/thing/disk-password";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "root" = {
                        mountpoint = "/";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "home" = {
                        mountpoint = "/home";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "compress=zstd" "noatime" "noacl" ];
                      };
                      "persist" = {
                        mountpoint = "/persist";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "varlog" = {
                        mountpoint = "/var/log";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "swap" = {
                        mountpoint = "/swap";
                      mountOptions = [ ];
                        swap = {
                          swapfile = {
                            size = "24G";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
