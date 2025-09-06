# Building NixOS ISO for `hs` Host

This guide explains how to build a custom NixOS ISO for the `hs` host configuration on a VPS and install it on the target machine.

## Prerequisites

- An x86_64 Linux VPS (recommended: at least 2GB RAM, 20GB storage)
- SSH access to the VPS
- Git repository with your nix configuration

## Step 1: Set up the VPS

### 1.1 Create a VPS

Choose a provider that offers x86_64 Linux VPS:
- Hetzner Cloud (recommended, affordable)
- DigitalOcean
- Vultr
- Linode

Create an Ubuntu 22.04 or Debian 12 VPS with at least:
- 2 vCPUs
- 4GB RAM (more is better for faster builds)
- 40GB storage

### 1.2 Install Nix on the VPS

SSH into your VPS and run:

```bash
# Install Nix (multi-user installation)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Source nix profile
. /etc/profile.d/nix.sh

# Enable flakes and nix-command
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Verify installation
nix --version
```

## Step 2: Build the ISO

### 2.1 Clone your configuration

```bash
# Clone your nix configuration repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# Or if using a private repository
git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

### 2.2 Build the ISO

```bash
# Build the ISO image
nix build .#nixosConfigurations.hs-iso.config.system.build.isoImage

# The ISO will be created in ./result/iso/
ls -la ./result/iso/
```

The build process may take 15-30 minutes depending on your VPS resources.

## Step 3: Download ISO to your local machine

From your local machine (iMac):

```bash
# Download the ISO
rsync root@YOUR_VPS_IP:~/.config/nix/result/iso/nixos-hs.iso ~/Downloads
```

## Step 4: Create Bootable Media

### Option A: USB Drive (Physical Installation)

```bash
# On macOS, find your USB device
diskutil list

# Unmount the USB drive (replace diskN with your disk)
diskutil unmountDisk /dev/diskN

# Write ISO to USB (replace diskN with your disk number)
sudo dd if=nixos-hs.iso of=/dev/rdiskN bs=4m status=progress

# Eject the USB
diskutil eject /dev/diskN
```

### Option B: Remote Installation Methods

1. **IPMI/iDRAC/iLO**: Upload ISO through management interface
2. **Proxmox/VMware**: Upload ISO to datastore
3. **Dedicated Server Rescue Mode**: Some providers allow custom ISO boot

## Step 5: Install NixOS on Target Machine

### 5.1 Boot from ISO

1. Insert USB or configure remote boot
2. Boot the target machine from the ISO
3. Wait for the system to boot (you'll see a login prompt)

### 5.2 Connect via SSH

The installer has SSH enabled with:
- Root password: `nixos` (change immediately!)
- Your SSH key is already authorized

```bash
# From your iMac, SSH into the installer
ssh root@TARGET_MACHINE_IP

# First, change the root password
passwd
```

### 5.3 Partition the Disks

The ISO includes disko for automated partitioning:

```bash
# Run disko to partition and format the disks
# This will DESTROY ALL DATA on the target disks!
disko --mode disko /etc/nixos/disk-config.nix

# Verify the partitions
lsblk
zpool status
```

### 5.4 Install NixOS

```bash
# Generate hardware configuration
nixos-generate-config --root /mnt

# Install NixOS from your flake
nixos-install --flake github:YOUR_USERNAME/YOUR_REPO#hs --root /mnt

# Or if you want to use a local flake
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git /mnt/etc/nixos
nixos-install --flake /mnt/etc/nixos#hs --root /mnt
```

### 5.5 Reboot

```bash
# Reboot into the installed system
reboot
```

## Post-Installation

After rebooting:

1. SSH into the system using your key: `ssh yanlin@TARGET_MACHINE_IP`
2. Verify the system is working correctly
3. Update the configuration as needed
4. Set up any additional services

## Troubleshooting

### Build Failures

- Ensure you have enough disk space on the VPS
- Try increasing VPS resources (RAM/CPU)
- Check for network issues when downloading packages

### Boot Issues

- Verify UEFI/BIOS settings support both UEFI and Legacy boot
- Check that both drives are detected in BIOS
- Try booting with only one drive connected initially

### ZFS Issues

- If ZFS pool import fails, try: `zpool import -f rpool`
- Check disk IDs match those in disk-config.nix: `ls -la /dev/disk/by-id/`

### Network Issues in Installer

- Check network with: `ip a`
- Restart networking: `systemctl restart systemd-networkd`
- Check DHCP: `journalctl -u systemd-networkd`

## Cleanup

After successful installation:

1. Delete the ISO from VPS
2. Terminate the VPS if no longer needed
3. Secure wipe the USB drive if used

## Security Notes

- Change the default installer password immediately
- The ISO includes your SSH public key - keep it secure
- Consider using a private Git repository for your configurations
- Delete the ISO after installation to prevent unauthorized access
