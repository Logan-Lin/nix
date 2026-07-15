# Disk layout for the nadeshiko host, consumed by disko.
# Two SATA SSDs each carry a BIOS boot partition and an EFI system partition, and their remaining space forms the mirrored ZFS root pool rpool with datasets for the system, home, and the Nix store.
# A separate NVMe drive holds its own ZFS storage pool mounted at /mnt/storage.

{
  disko.devices = {
    disk = {
      main1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            esp1 = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      main2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            # Second EFI system partition on the mirror partner, kept bootable so the machine survives loss of either disk.
            esp2 = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-alt";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      storage = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WD_Blue_SN580_2TB_2444EL405513";
        content = {
          type = "zfs";
          pool = "storage";
        };
      };

    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
          normalization = "formD";
          canmount = "off";
          dnodesize = "auto";
        };
        mountpoint = "/";

        datasets = {
          root = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };

          "root/nixos" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "noauto";
              mountpoint = "/";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "root/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              canmount = "on";
              mountpoint = "/home";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "root/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              canmount = "on";
              mountpoint = "/nix";
              "com.sun:auto-snapshot" = "false";
            };
          };
        };
      };

      storage = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "lz4";
          acltype = "posix";
          xattr = "sa";
          relatime = "on";
        };
        mountpoint = "/mnt/storage";
      };

    };

  };
}
