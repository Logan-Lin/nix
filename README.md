# Nix Configuration

Flake-based NixOS configuration with home-manager.

## Commands

### Daily Use
```bash
# System rebuild
sudo nixos-rebuild switch --flake .#<host>
# or use alias: oss

# Home Manager
home-manager switch --flake .#yanlin@<host>
# or use alias: hms
# the full switch alias `fs` will perform system rebuild then home manager switch

# Update flake
nix flake update
```

### New Host Installation
```bash
# 1. Initialize disk with disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake .#<host>

# 2. Install NixOS
sudo nixos-install --flake .#<host>
```

### Occasional Commands
```bash
# Garbage collection
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Check flake
nix flake check
nix flake show

# Search packages
nix search nixpkgs <package>

# Rollback
sudo nixos-rebuild switch --rollback

# Build without switching
nixos-rebuild build --flake .#<host>
```

## Structure

```
.
├── flake.nix           # Entry point
├── hosts/
│   └── nixos/          # NixOS configurations
│       ├── system-default.nix
│       ├── home-default.nix
│       └── <host>/
├── modules/            # Reusable modules
├── config/             # Static config files
└── scripts/            # Helper scripts
```

## Workflows

### Project Management
`proj` - Launch tmux sessions from `config/projects.json`

### Quick Aliases
- `hms` - Rebuild home-manager
- `oss` - Rebuild NixOS system
- `cdf` - Interactive file search with cd
- `pwdf` - Get file path interactively

### Tmux Reminders
- Prefix: `Ctrl-a`
- Split: `|` and `-`
- Navigate: `hjkl`
- Resize: `HJKL`

## Service Management (NixOS)

```bash
# Container services
sudo systemctl start/stop/restart podman-<container>.service
sudo systemctl status podman-<container>.service
sudo journalctl -u podman-<container>.service -f  # Follow logs
sudo journalctl -u podman-<container>.service -n 100  # Last 100 lines

# Podman commands
sudo podman ps -a
sudo podman logs -f <container>
sudo podman exec -it <container> bash

# Other services
systemctl status <service>
journalctl -u <service> -f
systemctl list-timers
```

