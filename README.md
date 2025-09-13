# Personal Nix Configuration

A comprehensive Nix configuration for macOS and NixOS using nix-darwin and home-manager, featuring a modern development environment with vim-centric workflows and beautiful aesthetics. Includes a powerful NixOS home server configuration with ZFS storage, containerized services, and automated monitoring. Largely generated and maintained with Claude Code.

## ✨ Features

- **🎨 Beautiful UI**: Gruvbox dark theme across all applications
- **⌨️ Vim-centric**: Consistent vim keybindings throughout the stack
- **🚀 Modern CLI**: Enhanced tools with fuzzy finding, syntax highlighting, and smart completion
- **📦 Modular Design**: Separate configuration files for easy maintenance
- **🔄 Portable**: Reproducible across machines with a single command
- **⚙️ System Integration**: macOS customizations and system-level preferences via nix-darwin
- **🎨 Typography**: Nerd Fonts with programming ligatures and icon support

## 🚀 Quick Install

### macOS (Darwin)
Install directly from GitHub without cloning:

```bash
# Darwin system configuration
sudo darwin-rebuild switch --flake github:Logan-Lin/nix-config

# Home Manager configuration  
home-manager switch --flake github:Logan-Lin/nix-config#yanlin@iMac
```

### NixOS
For NixOS systems:

```bash
# Home server (hs)
sudo nixos-rebuild switch --flake github:Logan-Lin/nix-config#hs
home-manager switch --flake github:Logan-Lin/nix-config#yanlin@hs

# VPS server (vps)  
sudo nixos-rebuild switch --flake github:Logan-Lin/nix-config#vps
home-manager switch --flake github:Logan-Lin/nix-config#yanlin@vps

# ThinkPad laptop (thinkpad)
sudo nixos-rebuild switch --flake github:Logan-Lin/nix-config#thinkpad
home-manager switch --flake github:Logan-Lin/nix-config#yanlin@thinkpad
```

## 📁 Configuration Architecture

```
.
├── flake.nix          # Main flake configuration and package definitions
├── hosts/             # Host-specific configurations
│   ├── darwin/        # macOS hosts
│   │   ├── home-default.nix    # Common home configuration for Darwin
│   │   ├── system-default.nix  # Common system configuration for macOS
│   │   ├── iMac/      # iMac configuration
│   │   │   ├── system.nix  # System configuration
│   │   │   └── home.nix    # Home configuration (imports ../home-default.nix)
│   │   └── mba/       # MacBook Air configuration
│   │       ├── system.nix  # System configuration
│   │       └── home.nix    # Home configuration (imports ../home-default.nix)
│   └── nixos/         # NixOS hosts
│       ├── home-default.nix    # Common home configuration for NixOS
│       ├── hs/        # Home server configuration
│       │   ├── system.nix  # NixOS system configuration
│       │   ├── home.nix    # Home configuration (imports ../home-default.nix)
│       │   ├── hardware-configuration.nix  # Hardware detection results
│       │   ├── disk-config.nix  # ZFS and filesystem configuration
│       │   ├── containers.nix  # Container service definitions
│       │   └── proxy.nix   # Traefik reverse proxy configuration
│       ├── thinkpad/  # ThinkPad laptop configuration
│       │   ├── system.nix  # NixOS system configuration with KDE Plasma
│       │   ├── home.nix    # Home configuration (imports ../home-default.nix)
│       │   ├── hardware-configuration.nix  # Hardware detection results
│       │   └── disk-config.nix  # Disk and filesystem configuration
│       └── vps/       # VPS server configuration
│           ├── system.nix  # NixOS system configuration
│           ├── home.nix    # Home configuration (imports ../home-default.nix)
│           ├── hardware-configuration.nix  # Hardware detection results
│           ├── disk-config.nix  # Disk and filesystem configuration
│           ├── containers.nix  # Container service definitions (web, notifications)
│           └── proxy.nix   # Traefik reverse proxy configuration
├── modules/           # Home Manager configuration modules
│   ├── git.nix        # Git configuration with aliases and settings
│   ├── lazygit.nix    # Lazygit with gruvbox theme and custom keybindings
│   ├── nvim.nix       # Neovim configuration with plugins and keymaps
│   ├── ssh.nix        # SSH client configuration and host management
│   ├── tmux.nix       # Tmux setup with vim-like navigation
│   ├── zsh.nix        # Zsh with Powerlevel10k and modern CLI tools
│   ├── papis.nix      # Reference management system (includes package)
│   ├── rsync.nix      # File synchronization and backup (includes package)
│   ├── termscp.nix    # Terminal file transfer client (includes package)
│   ├── firefox.nix    # Firefox browser with extensions and bookmarks
│   ├── btop.nix       # Modern system monitor (includes package)
│   ├── ghostty.nix    # GPU-accelerated terminal emulator
│   ├── syncthing.nix  # File synchronization service (includes package)
│   ├── wireguard.nix  # Hub-and-spoke VPN networking
│   ├── borg-client.nix       # Borg backup system with automated scheduling
│   ├── plasma.nix     # KDE Plasma desktop environment configuration
│   └── homebrew.nix   # Homebrew and nix-homebrew configuration
├── config/            # Configuration files
│   ├── firefox/       # Firefox browser configuration
│   │   ├── bookmarks.nix
│   │   ├── extensions.nix
│   │   └── search.nix
│   ├── fonts.nix      # Font packages and configuration
│   ├── homeassistant/ # Home Assistant smart home configuration
│   │   ├── configuration.yaml  # Main HA configuration with reverse proxy
│   │   ├── automations.yaml    # Bedroom lighting automation via Zigbee
│   │   ├── scenes.yaml         # Scene definitions (empty, ready for use)
│   │   └── scripts.yaml        # Script definitions (empty, ready for use)
│   ├── immich.nix     # Immich photo management service configuration
│   ├── p10k.zsh       # Powerlevel10k theme configuration
│   ├── projects.json  # Project definitions
│   └── projects.nix   # Project shortcuts configuration
└── scripts/           # Utility scripts
    └── project-launcher.sh  # Dynamic project launcher with window configuration
```

## 📦 Module Unification

Starting with the btop.nix pattern, modules now handle both configuration and package installation. This eliminates duplication between module imports and package lists:

- **Unified Modules**: `btop.nix`, `papis.nix`, `rsync.nix`, `termscp.nix`, `syncthing.nix`
- **Pattern**: Each module includes `home.packages = [ pkgs.packageName ];`
- **Benefits**: Single source of truth, no version conflicts, cleaner configuration

## 🔄 Core Workflow

The configuration creates an integrated development environment with a clear workflow progression:

**Terminal Emulator (ghostty)** → **Shell (zsh)** → **Session Management (tmux)** → **Code Editing (nvim)** → **Version Control (git)**

### 🖥️ Terminal Emulator: Ghostty

**Configuration**: `modules/ghostty.nix`  
**Purpose**: GPU-accelerated terminal with native performance

#### Key Features:
- **GPU Acceleration**: Native performance with metal rendering on macOS
- **Gruvbox Theme**: Dark background (#14191f) matching the entire stack
- **Font**: JetBrainsMono Nerd Font for icon support and ligatures
- **Shell Integration**: Smart cursor, sudo awareness, and dynamic titles
- **Optimized Padding**: 4px window padding for clean appearance

#### Configuration Highlights:
- **10,000 lines scrollback** for extensive history
- **Mouse hide while typing** for distraction-free input
- **No bell notifications** for quiet operation
- **System Ghostty**: Uses system-installed version (install from ghostty.org)
- **Window Size**: Configured with larger default dimensions for comfortable workspace

### 🐚 Terminal: Zsh with Powerlevel10k

**Theme**: Powerlevel10k lean style with 2-line prompt showing `user@hostname`  
**Vim Mode**: Enabled with visual indicators

#### Key Features:
- **Smart Completion**: Case-insensitive with menu selection
- **Autosuggestions**: Fish-like command suggestions  
- **Syntax Highlighting**: Real-time command syntax highlighting
- **History Management**: Shared history with deduplication
- **Vim Mode Indicators**: Cursor shape changes and prompt symbols

#### Vim Mode Indicators:
- **Insert Mode**: Line cursor `|` + `❯` prompt (green)
- **Normal Mode**: Block cursor `█` + `❮` prompt  
- **Fast Switching**: 10ms escape timeout for responsive mode changes

#### Essential Aliases:
```bash
# Navigation with zoxide (smart cd replacement)
cd [query]         # Smart directory jumping with frecency
zi [query]         # Interactive directory selection with fzf
.., ..., ....      # Quick directory navigation

# Modern CLI tools
cat → bat          # Syntax highlighted file viewing
find → fd          # Fast file finding  
grep → rg          # Ripgrep for fast searching
top → btop         # Beautiful system monitor

# Git shortcuts
g, gs, ga, gc, gp, gl, gd, gco, gb  # Git operations

# Nix management
hm                 # home-manager shortcut
hms                # Quick home-manager switch (rebuild)

# Directory navigation helpers
cdf                # Interactive file/directory search with real-time preview
                   # Type to search, Enter to cd to selection or parent
pwdf               # Same as cdf but prints the full path instead of cd
                   # Returns file path for files, directory path for dirs

# Application launcher
app [file]         # Interactive macOS app selector with fzf
                   # Optional: open file with selected app
```

### 🖥️ Session Management: Tmux

**Prefix Key**: `Ctrl+a` (instead of default `Ctrl+b`)  
**Theme**: Gruvbox dark with visual prefix indicator, hostname display, and remote host indicator

#### Key Features:
- **Prefix Indicator**: Shows `<Prefix>` in status bar when prefix is active (red background)
- **Remote Host Indicator**: Status bar background turns yellow when connected via SSH
- **Vim-like Navigation**: hjkl for pane movement
- **Smart Splitting**: Maintains current directory when creating panes
- **Copy Mode**: System clipboard integration

#### Essential Keybindings:

**Pane Management:**
| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix key |
| `Ctrl+a \|` | Split window vertically |
| `Ctrl+a -` | Split window horizontally |
| `Ctrl+a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+a H/J/K/L` | Resize panes (5 chars at a time) |
| `Ctrl+a Ctrl+a` | Quick pane cycling |

**Window Management:**
| Key | Action |
|-----|--------|
| `Ctrl+a c` | Create new window (preserves current path) |
| `Ctrl+a 1-9` | Switch to window by number |
| `Ctrl+a n` | Next window |
| `Ctrl+a p` | Previous window |
| `Ctrl+Shift+Left` | Move window left and follow |
| `Ctrl+Shift+Right` | Move window right and follow |
| `Ctrl+a .` | Move window (prompts for new index) |

**Session & Config:**
| Key | Action |
|-----|--------|
| `Ctrl+a d` | Detach from current session |
| `Ctrl+a s` | List and switch sessions |
| `Ctrl+a r` | Reload tmux config |
| `Ctrl+a A` | Toggle activity monitoring (useful for silencing noisy programs) |

#### Copy Mode (Ctrl+a [):
| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `y` | Copy selection to system clipboard |
| `r` | Toggle rectangle selection |

### 🚀 Project Management

**Configuration**: `config/projects.nix`  
**Purpose**: Quick access to project workspaces with tmux sessions

#### Usage:
```bash
proj                  # Interactive project selector with fzf
                      # Shows description, windows, and live tmux status
                      # Preview includes running/not running status
proj nix-config       # Direct launch (non-interactive mode)
proj blog             # Direct launch (non-interactive mode)
```

#### Window-Based Configuration:
Projects are configured with flexible window groups, allowing multiple working directories and customized window types per project.

**Window Types:**
- **nvim**: Code editing with Neovim (created by default)
- **ai**: AI assistant with three-pane layout
- **git**: Git management with lazygit
- **shell**: Plain shell window
- **remote**: SSH connection with dual panes

**Example Configuration:**
```nix
blog = {
  session = "blog";
  description = "Personal blog project";
  windows = [
    {
      name = "code";
      path = "~/Projects/personal-blog";
      ai = true;
      git = true;
      remote = {
        server = "personal-vps";     # SSH host from ~/.ssh/config
        remoteDir = "~/blog";        # Remote directory path
      };
    }
    {
      name = "content";
      path = "~/Projects/personal-blog/content";
      ai = true;
      git = true;
    }
  ];
};
```

### 📝 Code Editing: Neovim

**Theme**: Gruvbox dark with hard contrast  
**Leader Key**: `<Space>`

#### Key Features:
- **File Explorer**: nvim-tree with dotfile filtering
- **Tab Bar**: bufferline with seamless integration alongside file tree
- **Fuzzy Finder**: Telescope for fast file finding, text search, and navigation
- **Syntax Highlighting**: Treesitter with comprehensive language support
- **Git Integration**: vim-fugitive for git operations
- **Status Line**: lualine with gruvbox theme and relative paths
- **Indent Guides**: Subtle indent lines for better code structure visibility
- **System Clipboard**: Seamless integration for copy/paste  
- **Markdown Rendering**: render-markdown.nvim for beautiful in-buffer preview
- **Auto-completion**: Basic word and path completion

#### Essential Keybindings:

**File Operations:**
| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file explorer |
| `<Space>w` | Save file |
| `<Space>q` | Quit |
| `<Space>o` | Open file with system default app |
| `<Space>f` | Show current file in Finder |


**Buffer/Tab Navigation:**
| Key | Action |
|-----|--------|
| `<S-h>` | Previous buffer/tab |
| `<S-l>` | Next buffer/tab |
| `<Space>x` | Close current buffer |

**Fuzzy Finding (Telescope):**
| Key | Action |
|-----|--------|
| `<Space>t` | Find files in current directory |
| `<Space>g` | Live grep - search text in all files |

**Telescope Navigation:**
| Key | Action |
|-----|--------|
| `<C-j>/<C-k>` | Navigate up/down in results |
| `<CR>` | Open selected file |
| `<C-q>` | Send results to quickfix list |
| `<Esc>` | Close Telescope |

**File Explorer (nvim-tree):**
| Key | Action |
|-----|--------|
| `r` | Rename file/folder |
| `a` | Create new file/folder (end with `/` for folder) |
| `d` | Delete file/folder |
| `x` | Cut file/folder |
| `c` | Copy file/folder |
| `p` | Paste |
| `y` | Copy name |
| `Y` | Copy relative path |
| `gy` | Copy absolute path |

**Other:**
| Key | Action |
|-----|--------|
| `<Space>md` | Toggle markdown rendering |

#### Auto-completion:
```
Ctrl+Space    # Trigger completion menu
Tab           # Navigate to next completion item
Shift+Tab     # Navigate to previous completion item  
Enter         # Accept selected completion
Ctrl+e        # Close completion menu
```

### 🌟 Version Control: Git

**Configuration**: `modules/git.nix`  
**Purpose**: Declarative git configuration with comprehensive aliases

#### Complete Aliases Reference:

| Alias | Command | Description |
|-------|---------|-------------|
| `git st` | `status` | Show working tree status |
| `git co` | `checkout` | Switch branches or restore files |
| `git br` | `branch` | List, create, or delete branches |
| `git ci` | `commit` | Record changes to repository |
| `git cm "msg"` | `commit -m` | Quick commit with message |
| `git ca` | `commit --amend` | Amend the last commit |
| `git up` | `pull --rebase` | Pull and rebase (cleaner history) |
| `git d` | `diff` | Show unstaged changes |
| `git dc` | `diff --cached` | Show staged changes |
| `git ds` | `diff --stat` | Show diff statistics |
| `git lg` | `log --color --graph...` | Beautiful colored log with graph |
| `git lga` | `log --color --graph... --all` | Same as lg but all branches |
| `git last` | `log -1 HEAD` | Show the last commit |
| `git sl` | `stash list` | List all stashes |
| `git sp` | `stash pop` | Apply and remove latest stash |
| `git ss` | `stash save` | Save current changes to stash |
| `git unstage` | `reset HEAD --` | Remove files from staging area |
| `git visual` | `!gitk` | Launch gitk GUI |

#### Git Authentication with git-credential-oauth
Modern OAuth-based authentication for Git operations:
- Secure token-based authentication without storing passwords
- Support for GitHub, GitLab, and other OAuth providers
- Automatic token refresh and management
- Integration with system keychain for secure credential storage

#### Git Visualization with lazygit
Launch `lazygit` in any git repository for:
- **Gruvbox Theme**: Consistent dark theme matching nvim and tmux
- **Interactive UI**: Commit graph, branch visualization, and file tree
- **Vim Keybindings**: j/k navigation, h/l for panels
- **Enhanced Diff Viewing**: Delta integration for syntax-highlighted diffs
- **Smart Operations**: Stage hunks, commit, push, pull, rebase interactively
- **Managed Configuration**: Settings versioned in nix for reproducibility

## ⚙️ System Customizations (macOS)

**Configuration**: `system/darwin/default.nix`  
**Purpose**: System-level macOS customizations, preferences, and homebrew integration via nix-darwin

#### Menu Bar Spacing Configuration
Customizes macOS menu bar item spacing for a cleaner look, especially useful on machines with notches:

- **NSStatusItemSpacing**: Controls horizontal spacing between menu bar items
- **NSStatusItemSelectionPadding**: Controls padding inside selection overlay

This configuration runs during system activation to apply menu bar spacing preferences without requiring manual `defaults` commands.

#### Spotlight Indexing (Disabled)
Spotlight indexing is completely disabled in this configuration to:
- Reduce CPU usage and battery drain
- Free up disk space (index can be several GB)
- Prevent unwanted file scanning

**⚠️ Warning**: Disabling Spotlight affects:
- Mail.app search functionality
- Time Machine file restoration interface
- App Store search
- Some third-party apps that rely on Spotlight

**Management Commands**:
```bash
# Check Spotlight status
sudo mdutil -a -s

# Re-enable Spotlight if needed
sudo mdutil -a -i on

# Rebuild index after re-enabling
sudo mdutil -E /
```

## 📦 Package Management: Homebrew Integration

**Configuration**: `modules/homebrew.nix`  
**Purpose**: Declarative management of GUI applications via Homebrew on macOS

### Key Features:
- **Declarative Management**: GUI applications defined in nix configuration
- **Automatic Updates**: Apps update with system rebuilds
- **Cleanup on Rebuild**: Removes unlisted applications (zap mode)
- **nix-homebrew Integration**: Homebrew itself managed by Nix

### Managed Applications:
- **Firefox**: Web browser
- **Ghostty**: GPU-accelerated terminal emulator  
- **Obsidian**: Note-taking and knowledge management
- **Inkscape**: Vector graphics editor
- **Snipaste**: Screenshot and annotation tool
- **SlidePilot**: Presentation remote control
- **Tencent Meeting**: Video conferencing
- **Ovito**: Scientific visualization software
- **WeChat**: Messaging and communication
- **Microsoft Office**: Word, Excel, and PowerPoint productivity suite
- **Rectangle**: Window management and organization tool

### Management Commands:
```bash
# All managed through darwin-rebuild
sudo darwin-rebuild switch --flake .

# Manual Homebrew operations (if needed)
brew list              # List installed formulae and casks
brew info <cask>      # Get info about a specific application
```

### Integration Details:
- Applications install to `/Applications` automatically
- Homebrew managed by nix-homebrew for reproducibility
- Both Intel and Apple Silicon apps supported via Rosetta

## 🔐 SSH Configuration

**Configuration**: `modules/ssh.nix`  
**Purpose**: Declarative SSH client configuration and host management

#### Key Features:
- **Declarative Hosts**: All SSH hosts defined in nix configuration
- **Version Controlled**: SSH config tracked with git alongside other configurations
- **Reproducible**: Same SSH setup deployable across multiple machines
- **Security**: Private keys remain local and untracked
- **Agent Configuration**: SSH keys automatically added to agent with wildcard host matching

## 🛠️ Development Tools

### Enhanced CLI Utilities

- **fzf**: Fuzzy finder for files, commands, and history with built-in zsh keybindings
- **fd**: Fast, user-friendly alternative to find
- **ripgrep (rg)**: Fast text search across codebases
- **bat**: Syntax-highlighted cat replacement with git integration
- **btop**: Modern system monitor with vim-like navigation
- **zoxide**: Smart cd replacement with frecency algorithm
- **httpie**: Modern HTTP client for API testing and development

### macOS Applications

Nix-managed GUI applications available in `/Applications`:

- **Maccy**: Lightweight clipboard manager with search (Shift+Cmd+C)
- **AppCleaner**: Thoroughly uninstall applications and their support files
- **IINA**: Modern media player with native macOS design
- **KeePassXC**: Cross-platform password manager
- **Syncthing**: Continuous file synchronization (managed as a service)
- **Hidden Bar**: Hide menu bar items for a cleaner desktop

#### Powerful Tool Combinations:
```bash
# Find and open file with interactive selection
nvim $(fd --type f | fzf)

# Search text content and open matching file  
nvim $(rg -l "search_term" | fzf)

# Preview files while selecting which one to edit
nvim $(fd --type f | fzf --preview 'bat --color=always {}')

# Smart directory navigation with zoxide
cd proj && nvim .        # Jump to project directory and edit
zi && fd "*.md" | fzf    # Interactive directory select, then find markdown files

# Interactive directory navigation with real-time search
cdf                      # Type to search files/directories across your home
                         # Shows preview of directories and file contents
                         # Enter to cd to selection or its parent directory

# Get file/directory path without changing location
pwdf                     # Search and print full path
cp "$(pwdf)" .           # Copy selected file
cat "$(pwdf)"            # Read selected file
cd "$(dirname "$(pwdf)")" # cd to parent of selected file
```

#### Built-in zsh keybindings:
- `Ctrl+T` - Insert selected files/directories into command line
- `Ctrl+R` - Search command history interactively  
- `Alt+C` - Change to selected directory

### Database Management

- **sqlite3**: Official SQLite command-line interface for local databases
- **lazysql**: LazyGit-style TUI database management tool for MySQL, PostgreSQL, and SQLite

### Development Languages & Tools

- **Python 3.12**: With uv (modern Python package manager providing 10-100x faster performance)
- **LaTeX**: Full TeXLive distribution for document preparation
- **Claude Code**: AI-powered coding assistant
- **GNU Make**: Essential build automation tool for C/C++ and other projects

#### uv (Python Package Management):
```bash
# Project initialization
uv init my-project && cd my-project
uv add requests pandas numpy        # Add dependencies
uv add --dev pytest black isort     # Add dev dependencies
uv sync                            # Install from lock file

# Virtual environment management
uv venv                            # Create virtual environment
uv run python script.py           # Run in venv context
uv tool run black --help          # Run tools without installing
```

### File Transfer & Network Tools

- **lftp**: Advanced command-line FTP/SFTP client with scripting capabilities and parallel transfers
- **ncdu**: NCurses Disk Usage analyzer for exploring directory sizes interactively

#### lftp Usage Examples:
```bash
# Connect to FTP/SFTP server
lftp ftp://user@server.com
lftp sftp://user@server.com

# Advanced operations
lftp -c "connect sftp://server; mirror -R local/ remote/"  # Sync directories
lftp -c "connect ftp://server; pget -n 4 large-file.zip"  # Parallel download
```

#### ncdu Usage:
```bash
ncdu                    # Analyze current directory
ncdu /                  # Analyze entire filesystem
ncdu -x                 # Stay on same filesystem (don't cross mount points)
```

## 🎨 Fonts & Typography

**Configuration**: Declaratively managed via Home Manager  
**Purpose**: Programming fonts with icon support and enhanced readability

### Nerd Fonts Collection

The configuration includes carefully selected programming fonts with icon patches:

- **DejaVu Fonts**: Complete font family with excellent Unicode coverage and readability
- **Fira Code**: Coding font with programming ligatures and clean aesthetics
- **JetBrains Mono**: Modern monospace font designed specifically for developers

#### Features:
- **Icon Support**: Thousands of glyphs from popular icon fonts (Font Awesome, Devicons, etc.)
- **Programming Ligatures**: Enhanced code readability with connected character combinations
- **Terminal Integration**: Optimized for terminal emulators and code editors
- **Cross-platform**: Consistent appearance across different applications

#### Usage in Applications:
```bash
# Terminal applications automatically use configured fonts
# Neovim, tmux, and other TUI apps benefit from icon support
# Programming ligatures enhance code readability in editors
```

The fonts are automatically installed and configured system-wide through the nix configuration, ensuring consistency across all development tools.

## 🌐 Web Browser: Firefox

**Configuration**: `modules/firefox.nix`  
**Purpose**: Declarative Firefox configuration with extensions, bookmarks, and privacy settings

### Key Features:
- **Extensions Management**: Declarative installation of browser extensions via Nix
- **Bookmarks**: Pre-configured bookmarks with keywords for quick access
- **Privacy Settings**: Enhanced tracking protection and telemetry disabled
- **Search Engines**: Custom search engines with convenient aliases
- **Performance**: Hardware acceleration and WebRender enabled

### Configured Extensions:
- **uBlock Origin**: Advanced ad and tracker blocking

### Search Engine Aliases:
- `@np [query]` - Search Nix packages
- `@nw [query]` - Search NixOS Wiki
- `@g [query]` - Google search (manually configured for macOS compatibility)

### Privacy & Security:
- HTTPS-only mode enabled by default
- Enhanced tracking protection active
- All telemetry and experiments disabled
- Pocket integration removed
- Firefox View completely disabled (button hidden via userChrome.css)

### UI Customizations:
- Firefox View functionality and button removed entirely
- Password manager and form autofill disabled
- Search suggestions disabled for privacy
- Sidebar features hidden

### Usage:
```bash
# Firefox is managed declaratively through Nix
# Extensions are automatically installed and updated
# Bookmarks and settings sync across rebuilds
```

## 🖥️ Desktop Environment: KDE Plasma (ThinkPad)

**Configuration**: `modules/plasma.nix`  
**Purpose**: Declarative KDE Plasma 6 desktop environment configuration for ThinkPad laptop

### Key Features:
- **Dark Theme**: Breeze Dark theme with consistent dark appearance
- **Terminal Integration**: Konsole with JetBrainsMono Nerd Font and optimized layout
- **Minimal UI**: Auto-hiding taskbar and borderless maximized windows
- **Application Launcher**: Pre-configured dock with essential applications

### Konsole Configuration:
- **Font**: JetBrainsMono Nerd Font (size 13) for icon support
- **Theme**: Breeze dark color scheme matching system theme
- **Layout**: Clean interface with hidden menu bars and toolbars
- **Tab Management**: Intelligent tab bar that shows only when needed

### Panel Configuration:
- **Auto-hiding Taskbar**: Bottom panel that hides automatically for maximum screen real estate
- **Essential Widgets**: Application launcher, task manager, system tray, and clock
- **Quick Launch**: Pre-configured launchers for Dolphin, Firefox, Obsidian, Konsole, and KeePassXC
- **System Integration**: Battery, network, Bluetooth, and volume controls

### Application Defaults:
The ThinkPad configuration includes desktop-specific applications:
- **Obsidian**: Note-taking and knowledge management
- **KeePassXC**: Password manager with KDE integration  
- **Firefox**: Web browser with desktop optimizations
- **LaTeX**: Full TeXLive distribution for document preparation

### Window Management:
- **Borderless Maximized**: Maximized windows have no borders for clean appearance
- **KWin Integration**: Advanced window management with Plasma's compositor

## 🌟 Specialized Tools

### 📖 Offline Dictionary: sdcv

**Configuration**: `modules/dictionary.nix`  
**Purpose**: Command-line offline dictionary system with English and Japanese dictionaries

A declarative offline dictionary system using sdcv (StarDict Console Version):

#### Key Features:
- **Complete Offline Access**: No internet required for dictionary lookups
- **Multiple Dictionary Types**: English-English, Japanese-English, and English-Japanese
- **Declarative Downloads**: Dictionary files automatically downloaded and configured
- **Shell Integration**: Convenient aliases for different dictionary types
- **Reproducible Setup**: Dictionary configuration managed through Nix

#### Available Dictionary Aliases:
```bash
# English-English dictionary (primary)
def word                    # Look up English word
define word                 # Same as def

# Japanese-English dictionary
j2e 単語                    # Short alias for Japanese-English
e2j word                    # English to Japanese lookup

# Utility commands
dict-list                   # List all available dictionaries
dict-setup                  # Manually download/setup dictionary files
dict-disable-auto-setup     # Disable automatic dictionary setup
```

#### Features:
- **Automatic Download**: Dictionary files downloaded from archive.org sources
- **Smart Caching**: Files only downloaded once, marked as extracted
- **Environment Integration**: `STARDICT_DATA_DIR` configured automatically
- **Multiple Formats**: Supports .ifo, .dict, and .idx StarDict format files

### 📚 Reference Management: papis

**Purpose**: Command-line reference manager for academic papers and documents

A powerful bibliography manager with centralized storage at `~/Documents/Library/papis`:

#### Key Features:
- **Document Library**: Centralized storage with human-readable YAML metadata
- **BibTeX Integration**: Import/export references in standard academic formats
- **PDF Management**: Automatic file organization and retrieval
- **Search & Filter**: Fast document discovery with fuzzy finding (fzf)
- **Editor Integration**: Configured with nvim for editing document metadata

#### Usage Examples:
```bash
# Adding documents
papis add --from doi 10.1000/example.doi
papis add paper.pdf                    # Interactive metadata entry
papis add --from arxiv 2301.12345
papis add --from url https://example.com/paper.pdf

# Searching and browsing  
papis list "machine learning"
papis list author:smith year:2023
papis open                             # Uses fzf picker
papis open bohm

# Document management
papis edit bohm                        # Edit metadata with nvim
papis export --format bibtex query_term > references.bib
```

#### Workflow Aliases:
```bash
pals                          # List documents with formatted template
paadd                         # Add a new entry with BibTeX string
pabib                         # Print documents in BibTeX format
pacite                        # Print documents as citation strings
pafile filename.pdf           # Add file from ~/Downloads/
paopen                        # Open documents interactively  
pafinder "query"              # Open document directory in Finder
patag "tag1#tag2" "query"     # Add multiple tags using # separator
pareset                       # Reset and rebuild papis database
```

### 🔄 File Synchronization: rsync

**Purpose**: Declarative file synchronization and backup management

#### Configuration Files:
- `~/.rsync-exclude` - Common exclude patterns (macOS metadata, temp files)
- `~/.rsync-backup.conf` - Standard backup options with safety features
- `~/.local/bin/rsync-backup` - Convenient backup wrapper script
- `~/.rsync-aliases` - Shell aliases for common operations

#### Usage Examples:
```bash
# Using the backup wrapper
rsync-backup ~/Documents/ /backup/documents/

# Using shell aliases (source ~/.rsync-aliases first)
rsync-quick source/ dest/     # Basic backup with progress
rsync-dry source/ dest/       # Dry run for testing (safe)
rsync-sync source/ dest/      # Sync without deleting files
rsync-mirror source/ dest/    # Mirror with delete (exact copy)
```

### 📁 File Transfer: termscp

**Purpose**: Comprehensive TUI file transfer client

A rich terminal UI file transfer client with multi-protocol support:

#### Features:
- **Rich TUI**: Interactive file browser with dual-pane view
- **Multi-protocol**: FTP, SFTP, SCP, S3, WebDAV support  
- **Bookmarks**: Save frequently accessed servers
- **File Operations**: Create, rename, delete, search, edit files
- **Synchronization**: Sync directories between local and remote

```bash
termscp                       # Launch TUI client
ftp                          # Alias for termscp
termscp ftp://user@host.com  # Quick connection
```

## 💻 Daily Workflow

### Typical Development Session:

1. **Start Terminal**: Beautiful zsh with vim mode and modern tools
2. **Navigate to Project**: Use `zi` (zoxide + fzf) for smart directory jumping
3. **Launch Project Session**: Use project shortcuts (e.g., `website`, `research-project`)
4. **Tmux Environment**: Automatic session with nvim, git, and shell panes
5. **Code & Commit**: Integrated vim-style editing with git operations
6. **File Operations**: Use fzf + fd/rg for fast file finding and content search

### Environment Management:
```bash
# Refresh shell environment after nix changes
exec zsh

# Update and rebuild configuration
nix flake update
sudo darwin-rebuild switch --flake .
home-manager switch --flake .#yanlin

# Quick home-manager rebuild
hms
```

### Clipboard Integration:
- **Neovim**: `<Space>y/p` for system clipboard
- **Tmux**: Copy mode automatically uses system clipboard  
- **Terminal**: Standard Cmd+C/V works everywhere

## 📦 Automated Backups: Borg

**Configuration**: `modules/borg-client.nix`  
**Purpose**: Deduplicating archiver with compression and encryption for automated backups

### Key Features:
- **Encrypted Backups**: Repository encrypted with passphrase for security
- **Deduplication**: Space-efficient incremental backups
- **Automated Scheduling**: Systemd timer for unattended daily backups
- **Flexible Configuration**: Host-specific backup paths, retention policies, and frequencies
- **Progress Monitoring**: Detailed logging and status reporting

### Default Configuration (Home Server):
- **Backup Paths**: `/home` and `/var/lib/containers`
- **Repository**: `ssh://storage-box/./hs` (Hetzner Storage Box via SSH)
- **Schedule**: Daily backups with 30-minute random delay
- **Retention**: 7 daily, 4 weekly, 6 monthly, 2 yearly
- **Compression**: LZ4 with level 6 (balanced speed/size)

### Command Line Usage:

#### Manual Backup Operations:
```bash
# Initialize repository (first-time setup)
borg-init                      # Initialize encrypted repository

# Start manual backup
borg-backup-now                # Trigger immediate backup

# Check backup status  
borg-status                    # View service and timer status
borg-logs                      # Follow backup logs in real-time
```

#### Direct Borg Commands:
```bash
# Set up environment for direct borg commands
export BORG_REPO=ssh://storage-box/./hs
export BORG_RSH="ssh -F /home/yanlin/.ssh/config"

# Browse backup contents
borg list                      # List all archives
borg list ::<archive-name>     # List files in specific archive

# Extract files
borg extract ::<archive-name>  # Extract entire archive
borg extract ::<archive-name> path/to/file  # Extract specific files

# Repository maintenance
borg check                     # Verify repository consistency
borg info ::<archive-name>     # Show archive details and statistics
```

### Configuration Options:
- **repositoryUrl**: Local path or remote SSH URL for backup storage
- **backupPaths**: List of directories to include in backups
- **backupFrequency**: Systemd timer frequency (daily, hourly, or OnCalendar format)
- **retention**: Flexible policy for keeping daily/weekly/monthly/yearly backups
- **excludePatterns**: Comprehensive list of files/directories to skip
- **compressionLevel**: Balance between backup speed and storage efficiency

### Security Setup:
```bash
# Create passphrase file (required for repository encryption)
# Format: BORG_PASSPHRASE=yourpassphrase
echo "BORG_PASSPHRASE=your-secure-passphrase" | sudo tee /etc/borg-passphrase
sudo chmod 600 /etc/borg-passphrase
```

## 🔒 Secure Networking: WireGuard VPN

**Configuration**: `modules/wireguard.nix`  
**Purpose**: Hub-and-spoke VPN for secure connectivity between VPS and home server

### Network Architecture:
- **VPS (Hub)**: 10.2.2.1/24 - Central WireGuard server with public endpoint
- **HS (Spoke)**: 10.2.2.20/24 - Home server connecting through VPS
- **ThinkPad (Spoke)**: 10.2.2.30/24 - Laptop connecting through VPS
- **iPhone**: 10.2.2.31/24 - iOS device (mobile connectivity)
- **iPad**: 10.2.2.32/24 - iOS device (tablet connectivity)
- **LAN Access**: HS remains accessible at 10.1.1.152 on local network
- **DNS Setup**: hs.yanlincs.com resolves to 10.1.1.152 (LAN) with 10.2.2.20 (WireGuard) fallback

### Key Features:
- **Hub-and-Spoke Topology**: VPS acts as central gateway for all connections
- **Dual Access**: Home server accessible via both LAN (10.1.1.152) and WireGuard (10.2.2.20)
- **Automatic Key Management**: Private keys generated and managed per host
- **Firewall Integration**: Automatic firewall rules and IP forwarding
- **Systemd Integration**: Uses wg-quick for reliable service management

### Command Line Usage:

#### Service Management:
```bash
# Check WireGuard status
sudo systemctl status wg-quick-wg0

# Start/stop WireGuard
sudo systemctl start wg-quick-wg0
sudo systemctl stop wg-quick-wg0

# View WireGuard interface status
sudo wg show

# Check connectivity
ping 10.2.2.1  # Ping VPS from HS
ping 10.2.2.20 # Ping HS from VPS
```

#### Key Management:
```bash
# View public key (add to peer configurations)
sudo wg pubkey < /etc/wireguard/private.key

# Generate new keys if needed
wg genkey | sudo tee /etc/wireguard/private.key
sudo wg pubkey < /etc/wireguard/private.key
```

### Configuration Details:
- **Server Mode**: Configured on VPS with NAT forwarding and firewall rules
- **Client Mode**: Configured on HS with persistent keepalive to VPS
- **iOS Devices**: iPhone and iPad configurations available in `wireguard-configs/`
- **Automatic Startup**: Enabled via systemd wg-quick service
- **Key Storage**: Private keys stored in `/etc/wireguard/private.key` with 600 permissions
- **Port**: Default UDP 51820 (configurable)

### Setup Process:
1. Deploy configurations to both VPS and HS
2. Retrieve public keys from each host after first boot
3. Update peer configurations with actual public keys and VPS endpoint IP
4. Restart WireGuard services to establish connection

### iOS Device Setup:
1. Install WireGuard app from App Store on your iPhone/iPad
2. Configuration files are available in `wireguard-configs/`:
   - `iphone.conf` - iPhone configuration (10.2.2.30)
   - `ipad.conf` - iPad configuration (10.2.2.31)
3. Import configuration to WireGuard app:
   - Option 1: Generate QR code: `qrencode -t ansiutf8 < wireguard-configs/iphone.conf`
   - Option 2: Email/AirDrop the .conf file to your device
   - Option 3: Manually enter configuration in the app
4. Enable the VPN connection in WireGuard app
5. Test connectivity: Access internal services at 10.2.2.1 (VPS) or 10.2.2.20 (HS)

## 🏠 Home Server (`hs` Host)

The `hs` NixOS configuration provides a comprehensive home server solution with enterprise-grade storage, containerized services, and automated monitoring.

### 💾 Storage Architecture

#### ZFS Configuration
- **Boot Pool (`rpool`)**: Mirrored ZFS pool across two 1TB NVMe SSDs
  - GRUB bootloader with ZFS support on both drives
  - Automatic snapshots: 4 frequent (15min), 24 hourly, 7 daily, 4 weekly, 12 monthly
  - Monthly scrub for data integrity verification
  - Weekly TRIM for SSD optimization

- **Cache Pool**: Additional ZFS pool for high-performance caching
  - Configured with optimized ARC settings for 32GB system (16GB max ARC, 2GB min)

#### Data Storage
- **Primary Storage**: Two 12TB HGST drives formatted with XFS
  - Mounted at `/mnt/wd-12t-1` and `/mnt/wd-12t-2`
  - Optimized with `noatime` for better performance
  - Combined into unified storage via MergerFS at `/mnt/storage`

- **MergerFS Union Filesystem**: 
  - Intelligent file placement using "most free space" policy
  - Partial file caching for improved performance
  - Transparent access to combined storage pool

#### Data Protection
- **SnapRAID Parity**: 16TB Seagate drive provides parity protection
  - Automated daily sync at 3:00 AM
  - Weekly scrub for verification and error correction
  - Content files stored redundantly across multiple drives
  - Excludes temporary files, system files, and macOS metadata

### 🐳 Containerized Services

Comprehensive suite of self-hosted services managed via Podman with automatic startup:

#### Media & Entertainment
- **Plex Media Server**: Personal media streaming with hardware transcoding
- **Immich**: Photo and video backup with AI-powered organization
  - Declarative configuration in `config/immich.nix`
  - Intel QuickSync Video hardware acceleration for transcoding
  - Facial recognition and smart search enabled
  - Automatic nightly maintenance tasks
  - File organization by date pattern: `{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}`
- **Sonarr/Radarr/Bazarr**: Automated TV show, movie, and subtitle management
- **qBittorrent**: BitTorrent client with web interface

#### Home Automation & Monitoring
- **Home Assistant**: Smart home automation with USB Zigbee integration
  - Declarative configuration in `config/homeassistant/`
  - Bedroom lighting automation via Zigbee switch
  - Reverse proxy trust configuration for Traefik
  - Configuration and automations version-controlled and backed up
- **Syncthing**: Secure file synchronization across devices

#### Productivity & Knowledge Management
- **Nextcloud**: Private cloud storage and collaboration platform
- **Paperless-NGX**: Document management with OCR (English/Chinese)
- **Miniflux (RSS)**: Feed reader with clean interface
- **Linkding**: Bookmark manager with tagging

#### Supporting Services
- **Traefik**: Reverse proxy with automatic SSL certificates
- **PostgreSQL**: Database backend for Immich and Miniflux
- **MariaDB**: Database backend for Nextcloud
- **Redis**: Caching for Immich and Paperless

### 🌐 Network & Security

#### Reverse Proxy (Traefik)
- **Automatic SSL**: Cloudflare DNS challenge for `*.hs.yanlincs.com` certificates
- **Service Discovery**: Automatic routing to containerized services
- **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
- **Subdomains**: Each service accessible via dedicated subdomain

#### File Sharing (Samba)
- **SMB Protocol**: Modern Samba configuration for cross-platform access
- **Security**: User authentication required, guest access disabled
- **Performance**: Optimized socket options and sendfile support
- **Shares**: Media directory accessible to authenticated users

### 🔍 Monitoring & Maintenance

#### Disk Health Monitoring
- **SMART Monitoring**: Real-time disk health tracking via smartd
- **Automated Alerts**: Notifications for disk issues or failures
- **Daily Reports**: Comprehensive SMART status reports
- **Temperature Monitoring**: Alerts for overheating drives
- **Proactive Replacement**: Early warning system for failing drives

#### System Services
- **Automatic Updates**: NixOS configuration management
- **Log Rotation**: Automated cleanup of system and service logs
- **Service Health**: Container monitoring and automatic restart
- **Performance Monitoring**: System resource tracking

### 📍 Service Access

All services accessible via DNS with dual-IP resolution (LAN: 10.1.1.152, WireGuard: 10.2.2.20) with SSL certificates:

| Service | URL | Purpose |
|---------|-----|---------|
| Home Assistant | `home.hs.yanlincs.com` | Smart home automation |
| Immich | `photo.hs.yanlincs.com` | Photo/video backup |
| Plex | `plex.hs.yanlincs.com` | Media streaming |
| Nextcloud | `cloud.hs.yanlincs.com` | File sync and sharing |
| Paperless | `paperless.hs.yanlincs.com` | Document management |
| RSS Reader | `rss.hs.yanlincs.com` | Feed aggregation |
| Bookmarks | `link.hs.yanlincs.com` | Link management |
| Sonarr | `sonarr.hs.yanlincs.com` | TV show management |
| Radarr | `radarr.hs.yanlincs.com` | Movie management |
| Bazarr | `bazarr.hs.yanlincs.com` | Subtitle management |
| qBittorrent | `qbit.hs.yanlincs.com` | BitTorrent client |
| Syncthing | `syncthing.hs.yanlincs.com` | File synchronization |

## 🌐 VPS Server (`vps` Host)

The `vps` NixOS configuration provides a public-facing web server with notification services and automated backups.

### 🌍 Web Services

#### Public Website & Blog
- **Homepage**: Static Nginx server hosting main website at `www.yanlincs.com`
- **Blog**: Static Nginx server hosting personal blog at `blog.yanlincs.com`
- **SSL Certificates**: Automatic certificate generation via Traefik with Cloudflare DNS challenge
- **Domain Configuration**: Wildcard certificates for `*.yanlincs.com`

### 📱 Notification System

#### Gotify Server
- **Purpose**: Self-hosted notification server for system alerts and monitoring
- **Features**: REST API for sending notifications, web UI for management
- **Integration**: Connected to backup systems for status notifications
- **Access**: `notify.yanlincs.com`

#### iGotify Assistant
- **Purpose**: iOS notification bridge for Gotify server
- **Features**: Push notifications to iOS devices via Apple Push Notification service
- **Access**: `inotify.yanlincs.com`

### 🔒 Security & Backup

#### Automated Backups
- **Borg Backup**: Daily encrypted backups to Hetzner Storage Box
- **Backup Paths**: `/home` and `/var/lib/containers`
- **Retention Policy**: 7 daily, 4 weekly, 6 monthly, 2 yearly
- **Notifications**: Gotify integration for backup status alerts

#### Security Configuration
- **SSH Hardening**: Key-based authentication only, root login via keys
- **Firewall**: Only SSH (22), HTTP (80), and HTTPS (443) ports open
- **Container Security**: No new privileges, security-opt configurations

### 📍 VPS Service Access

All VPS services accessible via public domain with SSL certificates:

| Service | URL | Purpose |
|---------|-----|---------|
| Homepage | `www.yanlincs.com` | Main personal website |
| Blog | `blog.yanlincs.com` | Personal blog |
| Gotify | `notify.yanlincs.com` | Notification server |
| iGotify | `inotify.yanlincs.com` | iOS notification assistant |

## 💻 Machine Configurations

### Darwin Hosts (macOS)
- **`iMac`**: iMac configuration
- **`MacBook-Air`**: MacBook Air configuration

### NixOS Hosts
- **`hs`**: Home server configuration featuring ZFS storage, containerized services, and automated monitoring
- **`vps`**: VPS server configuration featuring:
  - **Web Services**: Public website and blog hosting with Nginx
  - **Notification System**: Gotify server for system notifications and alerts
  - **Automated Backups**: Borg backup with Gotify integration for status notifications
  - **SSL Certificates**: Traefik reverse proxy with Cloudflare DNS challenge
  - **Security**: Hardened SSH configuration and firewall settings
- **`thinkpad`**: ThinkPad laptop configuration featuring:
  - **KDE Plasma 6**: Modern desktop environment with dark theme
  - **Hardware Support**: Intel/NVIDIA hybrid graphics with power management
  - **Development Tools**: Full development environment with LaTeX, Obsidian, and KeePassXC
  - **Network Integration**: WireGuard VPN and SSH access via jump host

All hosts use a consistent configuration structure with separate system and home management.

### Configuration Structure:
The configuration has been reorganized for better clarity and consistency:

#### Darwin Hosts:
- **`hosts/darwin/`**: Contains all Darwin host configurations
  - **`home-default.nix`**: Common home configuration shared by all Darwin hosts
  - **`system-default.nix`**: Common system configuration for macOS
  - **Per-host directories**: Each host has its own directory with:
    - **`system.nix`**: Host-specific system configuration (imports ../system-default.nix)
    - **`home.nix`**: Host-specific home configuration (imports ../home-default.nix)

#### NixOS Host:
- **`hosts/nixos/`**: Contains NixOS host configurations
  - **`home-default.nix`**: Common home configuration for NixOS hosts
  - **`hs/`**: Home server specific directory with:
    - **`system.nix`**: NixOS system configuration (standalone, no home-manager)
    - **`home.nix`**: Home configuration (imports ../home-default.nix)
    - **`hardware-configuration.nix`**: Hardware-specific configuration
    - **`disk-config.nix`**: Disk and filesystem configuration

### Machine-specific Usage:

#### Darwin (macOS) Hosts:
```bash
# For MacBook Air
sudo darwin-rebuild switch --flake .#mba
home-manager switch --flake .#yanlin@mba

# For iMac  
sudo darwin-rebuild switch --flake .#imac
home-manager switch --flake .#yanlin@imac
```

#### NixOS Hosts:
```bash
# For home server (hs)
sudo nixos-rebuild switch --flake .#hs
home-manager switch --flake .#yanlin@hs

# For VPS server (vps)
sudo nixos-rebuild switch --flake .#vps
home-manager switch --flake .#yanlin@vps

# For ThinkPad laptop (thinkpad)
sudo nixos-rebuild switch --flake .#thinkpad
home-manager switch --flake .#yanlin@thinkpad
```

The separation of system and home configurations provides:
- **Consistent workflow** across all platforms
- **Clean separation of concerns** between system and user configurations
- **Independent updates** - update system or home environment separately
- **Better maintainability** with no duplicate configuration references

