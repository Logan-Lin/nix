# Nix Configuration

Flake-based NixOS configuration with home-manager.

## Structure

```
.
├── flake.nix       # Entry point
├── .github/
│   └── workflows/  # Automated workflows
├── hosts/
│   ├── nixos/      # NixOS configurations
│   └── darwin/     # Nix-darwin configurations
└── modules/        # Reusable modules
```

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

# Garbage collection
nix-collect-garbage -d
sudo nix-collect-garbage -d
brew cleanup --prune=all
```

### New Host Installation

```bash
# For NixOS and disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:Logan-Lin/nix#<host>
sudo nixos-install --flake .#<host>

# For nix-darwin
xcode-select --install
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:Logan-Lin/nix#<host>
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake github:Logan-Lin/nix#<user>@<host>
```

### Service Management

```bash
# Normal services
sudo systemctl start/stop/restart/status <service>
sudo journalctl -u <service> -f
sudo systemctl list-timers

# Container services
sudo systemctl start/stop/restart/status podman-<container>.service
sudo journalctl -u podman-<container>.service -f
```

