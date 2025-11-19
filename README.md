# Nix Configuration

Flake-based NixOS configuration with home-manager.

## Commands

### Daily Use
```bash
# System rebuild
sudo nixos-rebuild switch --flake .#<host>  # NixOS
sudo darwin-rebuild switch --flake .#<host>  # Nix-darwin
# or use alias: oss

# Home Manager
home-manager switch --flake .#<user>@<host>
# or use alias: hms
# the full switch alias `fs` will perform system rebuild then home manager switch

# Update flake
nix flake update
```

### New Host Installation
```bash
# For NixOS and disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:Logan-Lin/nix-config#<host>
sudo nixos-install --flake .#<host>

# For nix-darwin
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:Logan-Lin/nix-config#<host>
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake github:Logan-Lin/nix-config#<user>@<host>
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
```

## Structure

```
.
├── flake.nix           # Entry point
├── hosts/
│   ├── nixos/          # NixOS configurations
│   │   ├── system-default.nix
│   │   ├── home-default.nix
│   │   └── <host>/
│   └── darwin/         # Nix-darwin configurations
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
- `fm` - Open current directory in GUI file manager

### Tmux Reminders
- Prefix: `Ctrl-a`
- Split: `|` and `-`
- Navigate: `hjkl`
- Resize: `HJKL`

## Service Management

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

