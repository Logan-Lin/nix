# Nix Configuration

Flake-based NixOS and nix-darwin configuration with home-manager.

## Commands

### Daily Use
```bash
# System rebuild
sudo darwin-rebuild switch --flake .#<host>  # macOS
sudo nixos-rebuild switch --flake .#<host>   # NixOS
# or use alias: oss

# Home Manager
home-manager switch --flake .#yanlin@<host>
# or use alias: hms
# the full switch alias `fs` will perform system rebuild then home manager switch

# Update flake
nix flake update
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
sudo darwin-rebuild switch --rollback

# Build without switching
nixos-rebuild build --flake .#<host>
darwin-rebuild build --flake .#<host>
```

## Structure

```
.
├── flake.nix           # Entry point
├── hosts/
│   ├── darwin/         # macOS configurations
│   │   ├── system-default.nix
│   │   ├── home-default.nix
│   │   └── <host>/
│   └── nixos/          # NixOS configurations
│       ├── system-default.nix
│       ├── home-default.nix
│       └── <host>/
├── modules/            # Reusable modules
├── config/             # Static config files
└── scripts/            # Helper scripts
```

## Modules

Modules are self-contained and handle both package installation and configuration.

- `borg-client.nix` - Backup client with scheduling
- `borg-server.nix` - Backup server configuration
- `btop.nix` - System monitor with vim navigation
- `claude-code.nix` - AI coding assistant with permissions config
- `container-updater.nix` - Automated container updates
- `dictionary.nix` - Offline dictionary system (sdcv)
- `firefox.nix` - Browser with extensions and bookmarks
- `ghostty.nix` - GPU-accelerated terminal emulator
- `git.nix` - Version control with aliases
- `homebrew.nix` - macOS package management
- `lazygit.nix` - Terminal UI for git
- `login-display.nix` - SSH login display with system/disk info
- `nvim.nix` - Neovim editor configuration
- `papis.nix` - Academic reference manager
- `plasma.nix` - KDE desktop environment
- `podman.nix` - Container runtime
- `rsync.nix` - File synchronization tools
- `samba.nix` - SMB file sharing
- `scheduled-commands.nix` - Systemd timer service framework
- `ssh.nix` - SSH client configuration
- `syncthing.nix` - Continuous file synchronization
- `termscp.nix` - Terminal file transfer client
- `tex.nix` - LaTeX/TeX compilation environment
- `tmux.nix` - Terminal multiplexer
- `traefik.nix` - Reverse proxy with SSL
- `webdav.nix` - WebDAV file server
- `wireguard.nix` - VPN networking
- `yt-dlp.nix` - Video downloader with filtering
- `zsh.nix` - Shell with modern tools

## Scripts

- `container-update.sh` - Update container images safely
- `project-launcher.sh` - Tmux session manager for projects

## Custom Workflows

### Project Management
`proj` - Launch tmux sessions from `config/projects.json`

### Quick Aliases
- `hms` - Rebuild home-manager
- `oss` - Rebuild system (works on both Darwin/NixOS)
- `cdf` - Interactive file search with cd
- `pwdf` - Get file path interactively
- `zi` - Interactive zoxide with fzf

### Tmux Reminders
- Prefix: `Ctrl-a`
- Split: `|` and `-`
- Navigate: `hjkl`
- Resize: `HJKL`

### Git Aliases (in config)
- `lg` - Pretty log with graph
- `up` - Pull with rebase
- `cm` - Commit with message

## Service Management (NixOS)

```bash
# Check service status
systemctl status <service>
journalctl -u <service> -f

# Container management
docker ps  # Actually podman
docker logs <container>
docker exec -it <container> bash

# Systemd timers
systemctl list-timers
```

### Manual Timer Service Execution
- `dl-subs-yt` - Check YouTube subscriptions and download new videos
- `container-update-now` - Update container images manually
- `borg-backup-now` - Run backup manually

## Notes

- Borg backups need passphrase at `/etc/borg-passphrase`
- Container definitions use podman backend
- WireGuard configs need manual key exchange after first deploy
- Traefik handles SSL via Cloudflare DNS challenge

