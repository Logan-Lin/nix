# Disko configuration for ThinkPad P14s Gen 2
# Simple single-disk setup with EFI boot and ext4 root partition
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Update this to match your actual disk
        # Use 'lsblk' or 'fdisk -l' to find your disk identifier
        device = "/dev/nvme0n1"; # Common for NVMe SSDs in laptops
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };
            
            # Swap partition (optional, adjust size as needed)
            swap = {
              size = "16G"; # Match your RAM size for hibernation support
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            
            # Root partition - takes remaining space
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}