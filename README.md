# Yan Lin's Nix Configuration

Flake-based NixOS/nix-darwin configuration with home-manager.

## Structure

- `flake.nix`: Entry point, defines inputs and host outputs
- `flake.lock`: Pinned input versions
- `.github/workflows/`: automatic CI workflows for nix evaluation and flake updates
- `hosts/`: Per-host configurations, organized by platform
- `modules/`: Reusable modules shared across hosts

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

# Garbage collection
nix-collect-garbage -d
sudo nix-collect-garbage -d
brew cleanup --prune=all
```

### New Host Installation

```bash
# NixOS
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:Logan-Lin/nix#<host>
sudo nixos-install --flake github:Logan-Lin/nix#<host> --no-root-passwd

# nix-darwin
xcode-select --install
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:Logan-Lin/nix#<host>

# Home Manager
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake github:Logan-Lin/nix#<user>@<host>
```

