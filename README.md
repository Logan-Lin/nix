# Yan Lin's Nix Configuration

Flake-based NixOS/nix-darwin configuration with home-manager.

## Structure

- `flake.nix`: Entry point, defines inputs and host outputs
- `flake.lock`: Pinned input versions
- `.github/`
  - `workflows/`: CI builds and scheduled flake input updates
  - `scripts/`: Helper scripts used by workflows
- `hosts/`: Per-host configurations, organized by platform
  - `nixos/`: NixOS hosts, with shared `system-default.nix` and `home-default.nix` as common bases
  - `darwin/`: Nix-darwin hosts, following the same shared-defaults layout
- `modules/`: Reusable modules shared across hosts, either as single files (e.g. `git.nix`, `nginx.nix`) or grouped subdirectories (e.g. `terminal/`, `vpn/`, `share/`)

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
# For NixOS
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:Logan-Lin/nix#<host>
sudo nixos-install --flake .#<host>

# For nix-darwin
xcode-select --install
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:Logan-Lin/nix#<host>
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake github:Logan-Lin/nix#<user>@<host>
```

