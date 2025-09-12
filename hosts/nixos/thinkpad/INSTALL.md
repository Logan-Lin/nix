# NixOS Installation Guide for ThinkPad P14s Gen 2

This guide will walk you through installing NixOS on your Lenovo ThinkPad P14s Gen 2 with Intel i7 and NVIDIA T500 GPU.

## Prerequisites

- USB drive (4GB or larger)
- NixOS ISO image
- Ethernet cable or WiFi credentials
- This configuration repository

## Step 1: Prepare Installation Media

1. Download the latest NixOS ISO (GNOME or Plasma edition recommended for GUI installer):
   ```bash
   # Download from https://nixos.org/download.html
   # Choose the 64-bit Intel/AMD ISO
   ```

2. Write the ISO to USB drive:
   ```bash
   # On Linux/macOS:
   sudo dd if=nixos-24.05-x86_64.iso of=/dev/sdX bs=4M status=progress
   
   # On Windows: Use Rufus or Etcher
   ```

## Step 2: Boot from USB

1. Insert the USB drive into your ThinkPad
2. Press F12 during boot to access boot menu
3. Select the USB drive
4. Choose "NixOS Installer" from the boot menu

## Step 3: Connect to Internet

### Option A: Ethernet (Easiest)
Simply plug in an ethernet cable.

### Option B: WiFi
```bash
# List available networks
sudo nmcli device wifi list

# Connect to WiFi
sudo nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Verify connection
ping -c 3 nixos.org
```

## Step 4: Prepare Disk

### IMPORTANT: Identify Your Disk
```bash
# List all disks
lsblk

# Your NVMe SSD will likely be /dev/nvme0n1
# Verify the size matches your disk
```

### Update Disk Configuration
Edit the disk device in your configuration if needed:
```bash
# If your disk is not /dev/nvme0n1, you'll need to update disk-config.nix
# after cloning the repository (see next step)
```

## Step 5: Clone Configuration Repository

```bash
# Install git temporarily
nix-shell -p git

# Clone your configuration
git clone https://github.com/Logan-Lin/nix-config.git
cd nix-config

# If needed, update the disk device in hosts/nixos/thinkpad/disk-config.nix
nano hosts/nixos/thinkpad/disk-config.nix
# Change 'device = "/dev/nvme0n1"' to match your disk
```

## Step 6: Partition Disk with Disko

```bash
# This will ERASE your entire disk!
# Make sure you have backups of any important data

# Partition the disk according to disk-config.nix
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake .#thinkpad
```

## Step 7: Generate Hardware Configuration

```bash
# Generate hardware-configuration.nix
sudo nixos-generate-config --show-hardware-config > hosts/nixos/thinkpad/hardware-configuration.nix

# Review the generated file
cat hosts/nixos/thinkpad/hardware-configuration.nix
```

## Step 8: Find GPU Bus IDs

```bash
# Find your GPU bus IDs for NVIDIA PRIME
lspci | grep -E 'VGA|3D'

# You should see something like:
# 00:02.0 VGA compatible controller: Intel Corporation ...
# 01:00.0 3D controller: NVIDIA Corporation T500 ...

# Update system.nix with correct bus IDs:
nano hosts/nixos/thinkpad/system.nix

# Find and update these lines with your actual values:
# intelBusId = "PCI:0:2:0";
# nvidiaBusId = "PCI:1:0:0";
```

## Step 9: Install NixOS

```bash
# Install NixOS using the flake configuration
sudo nixos-install --flake .#thinkpad

# You will be prompted to set the root password
# (You can leave it blank since we use SSH keys and sudo)
```

## Step 10: Reboot

```bash
# Remove the USB drive and reboot
sudo reboot
```

## Step 11: Post-Installation Setup

After rebooting into your new NixOS system:

### Login
- Username: `yanlin`
- Password: Use the password you know (the hashed one in the config)

### Apply Home Manager Configuration
```bash
# Clone the config repo to your home directory
cd ~
git clone https://github.com/Logan-Lin/nix-config.git .config/nix

# Apply home-manager configuration
home-manager switch --flake ~/.config/nix#yanlin@thinkpad
```

### Verify NVIDIA Setup
```bash
# Check if NVIDIA driver is loaded
lsmod | grep nvidia

# Test NVIDIA offload
nvidia-offload glxgears

# Check GPU status
nvidia-smi
```

### Set Up Power Management
```bash
# Check TLP status
sudo tlp-stat

# Monitor battery
acpi -b

# Check CPU frequency scaling
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## Troubleshooting

### WiFi Not Working
- Some ThinkPad models need newer kernel: Already using latest kernel in config
- Check if WiFi is blocked: `rfkill list`

### NVIDIA Issues
- If NVIDIA doesn't work, boot with integrated graphics only:
  - Comment out the nvidia configuration in system.nix
  - Rebuild: `sudo nixos-rebuild switch --flake ~/.config/nix#thinkpad`

### Display Manager Not Starting
- Switch to TTY (Ctrl+Alt+F2)
- Check logs: `journalctl -xeu display-manager`

### Battery Drain
- Ensure TLP is running: `systemctl status tlp`
- Check if NVIDIA is always on: `cat /proc/acpi/bbswitch`
- Use `powertop` to identify power-hungry processes

## Useful Commands

```bash
# Rebuild system configuration
sudo nixos-rebuild switch --flake ~/.config/nix#thinkpad

# Rebuild home configuration
home-manager switch --flake ~/.config/nix#yanlin@thinkpad

# Update system
nix flake update ~/.config/nix
sudo nixos-rebuild switch --flake ~/.config/nix#thinkpad

# Check system health
nixos-option system.stateVersion
nix-store --verify --check-contents

# Clean up old generations
sudo nix-collect-garbage -d
```

## KDE Plasma Tips

- **Global Theme**: System Settings → Appearance → Global Theme
- **Display Configuration**: System Settings → Display and Monitor
- **Power Management**: System Settings → Power Management
- **NVIDIA Settings**: Run `nvidia-settings` from terminal or application menu
- **Virtual Desktops**: System Settings → Workspace → Virtual Desktops

## Running Applications with NVIDIA GPU

To run applications using the discrete NVIDIA GPU:
```bash
# Use the nvidia-offload command (alias: nvidia-run)
nvidia-offload firefox
nvidia-offload steam
nvidia-run blender
```

## Notes

- The configuration includes Firefox add-ons support for the home-manager setup
- Claude Code is available after home-manager installation
- The system is configured for maximum battery life with TLP
- NVIDIA GPU is set to power-saving offload mode by default
- KDE Plasma 6 with Wayland support is configured