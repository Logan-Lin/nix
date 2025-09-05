# Personal Nix Configuration

A comprehensive Nix configuration for macOS using nix-darwin and home-manager, featuring a modern development environment with vim-centric workflows and beautiful aesthetics. Largely generated and maintained with Claude Code.

## ✨ Features

- **🎨 Beautiful UI**: Gruvbox dark theme across all applications
- **⌨️ Vim-centric**: Consistent vim keybindings throughout the stack
- **🚀 Modern CLI**: Enhanced tools with fuzzy finding, syntax highlighting, and smart completion
- **📦 Modular Design**: Separate configuration files for easy maintenance
- **🔄 Portable**: Reproducible across machines with a single command
- **⚙️ System Integration**: macOS customizations and system-level preferences via nix-darwin
- **🎨 Typography**: Nerd Fonts with programming ligatures and icon support

## 🚀 Quick Install

Install directly from GitHub without cloning:

```bash
# Darwin system configuration
sudo darwin-rebuild switch --flake github:Logan-Lin/nix-config

# Home Manager configuration  
home-manager switch --flake github:Logan-Lin/nix-config#yanlin@iMac
```

## 📁 Configuration Architecture

```
.
├── flake.nix          # Main flake configuration and package definitions
├── hosts/             # Host-specific configurations
│   └── darwin/        # macOS hosts
│       ├── home-default.nix    # Common home configuration imported by all hosts
│       ├── system-default.nix  # Common system configuration for macOS
│       ├── iMac/      # iMac configuration
│       │   ├── system.nix  # System configuration
│       │   └── home.nix    # Home configuration (imports ../home-default.nix)
│       └── MacBook-Air/ # MacBook Air configuration
│           ├── system.nix  # System configuration
│           └── home.nix    # Home configuration (imports ../home-default.nix)
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
│   ├── tailscale.nix  # Secure networking and VPN service
│   └── homebrew.nix   # Homebrew and nix-homebrew configuration
├── config/            # Configuration files
│   ├── firefox/       # Firefox browser configuration
│   │   ├── bookmarks.nix
│   │   ├── extensions.nix
│   │   └── search.nix
│   ├── fonts.nix      # Font packages and configuration
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
**Theme**: Gruvbox dark with visual prefix indicator and hostname display

#### Key Features:
- **Prefix Indicator**: Shows `<Prefix>` in status bar when prefix is active
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
- **Fuzzy Finder**: Telescope for fast file finding, text search, and navigation
- **Syntax Highlighting**: Treesitter with comprehensive language support
- **Git Integration**: vim-fugitive for git operations
- **Status Line**: lualine with gruvbox theme and relative paths
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

## 🔒 Secure Networking: Tailscale

**Configuration**: `modules/tailscale.nix`  
**Purpose**: Secure mesh VPN for private networking across devices

### Key Features:
- **Automatic Startup**: Runs as a system service at boot
- **MagicDNS**: Access devices by name instead of IP addresses
- **Secure Connectivity**: Zero-configuration encrypted connections
- **Exit Nodes**: Route traffic through specific devices

### Command Line Usage:

#### Basic Operations:
```bash
# Check connection status and see all devices
tailscale status

# Connect to your Tailscale network (first-time setup)
tailscale up

# Disconnect temporarily
tailscale down

# View current Tailscale IP address
tailscale ip -4
```

#### Exit Node Management:
```bash
# List available exit nodes
tailscale exit-node list

# Use a specific exit node
tailscale set --exit-node=<hostname>
# or
tailscale up --exit-node=<hostname>

# Stop using exit node
tailscale set --exit-node=
# or
tailscale up --exit-node=

# Allow LAN access while using exit node
tailscale set --exit-node=<hostname> --exit-node-allow-lan-access
```

#### Advanced Usage:
```bash
# Get suggested exit node
tailscale exit-node suggest

# Check detailed network diagnostics
tailscale netcheck

# Show network configuration
tailscale debug netmap
```

### Configuration Details:
- **Auto-start**: Enabled via nix-darwin service management
- **DNS Override**: Uses Tailscale's MagicDNS (100.100.100.100) for name resolution
- **System Integration**: Runs as a daemon accessible to all users

## 💻 Machine Configurations

- **`iMac`**: iMac configuration
- **`MacBook-Air`**: MacBook Air configuration

Both machines use the same base configuration with potential for machine-specific customizations.

### Configuration Structure:
The configuration has been reorganized for better clarity:
- **`hosts/darwin/`**: Contains all host-related configurations
  - **`home-default.nix`**: Common home configuration shared by all hosts
  - **`system-default.nix`**: Common system configuration for macOS
  - **Per-host directories**: Each host has its own directory with:
    - **`system.nix`**: Host-specific system configuration (imports ../system-default.nix)
    - **`home.nix`**: Host-specific home configuration (imports ../home-default.nix)

The `home-default.nix` file contains all shared home configuration, including:
- Module imports (which now handle both configuration and package installation)
- Common packages not managed by modules
- Base home settings

### Machine-specific Usage:
```bash
# For MacBook Air
sudo darwin-rebuild switch --flake .#MacBook-Air
home-manager switch --flake .#yanlin@MacBook-Air

# For iMac  
sudo darwin-rebuild switch --flake .#iMac
home-manager switch --flake .#yanlin@iMac
```

