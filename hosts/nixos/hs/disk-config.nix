{
  disko.devices = {
    disk = {
      # First drive of ZFS mirror pair (ZHITAI 1TB #1)
      main1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R";
        content = {
          type = "gpt";
          partitions = {
            # GRUB BIOS boot partition
            boot = {
              size = "1M";
              type = "EF02";
            };
            # EFI System Partition (mirrored manually)
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
            # ZFS partition
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

      # Second drive of ZFS mirror pair (ZHITAI 1TB #2)
      main2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG";
        content = {
          type = "gpt";
          partitions = {
            # GRUB BIOS boot partition
            boot = {
              size = "1M";
              type = "EF02";
            };
            # EFI System Partition (backup)
            esp2 = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
              };
            };
            # ZFS partition
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
          # Root dataset
          root = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          
          # Root filesystem
          "root/nixos" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "noauto";
              mountpoint = "/";
              "com.sun:auto-snapshot" = "true";
            };
          };
          
          # Home directory
          "root/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              canmount = "on";
              mountpoint = "/home";
              "com.sun:auto-snapshot" = "true";
            };
          };
          
          # Nix store (no snapshots needed)
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

    };

  };
}