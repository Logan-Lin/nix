# Personal Nix Configuration

A comprehensive Nix configuration for macOS using nix-darwin and home-manager, featuring a modern development environment with vim-centric workflows and beautiful aesthetics. Largely generated and maintained with Claude Code.

## ✨ Features

- **🎨 Beautiful UI**: Gruvbox dark theme across all applications
- **⌨️ Vim-centric**: Consistent vim keybindings throughout the stack
- **🚀 Modern CLI**: Enhanced tools with fuzzy finding, syntax highlighting, and smart completion
- **📦 Modular Design**: Separate configuration files for easy maintenance
- **🔄 Portable**: Reproducible across machines with a single command

## 🚀 Quick Install

Install directly from GitHub without cloning:

```bash
# Darwin system configuration
sudo darwin-rebuild switch --flake github:Logan-Lin/nix-config

# Home Manager configuration  
home-manager switch --flake github:Logan-Lin/nix-config#yanlin
```

## 📁 Configuration Architecture

```
.
├── flake.nix          # Main flake configuration and package definitions
├── modules/           # Nix configuration modules
│   ├── git.nix        # Git configuration with aliases and settings
│   ├── nvim.nix       # Neovim configuration with plugins and keymaps
│   ├── ssh.nix        # SSH client configuration and host management
│   ├── tmux.nix       # Tmux setup with vim-like navigation
│   ├── zsh.nix        # Zsh with Powerlevel10k and modern CLI tools
│   ├── papis.nix      # Reference management system
│   ├── rsync.nix      # File synchronization and backup
│   └── termscp.nix    # Terminal file transfer client
├── config/            # Configuration files
│   ├── p10k.zsh       # Powerlevel10k theme configuration
│   └── projects.nix   # Project shortcuts configuration
└── scripts/           # Utility scripts
    ├── project-launcher.sh  # Universal project launcher
    └── templates/     # Tmux session templates
        ├── basic.sh   # Basic development template
        └── research.sh # Research workflow template
```

## 🔄 Core Workflow

The configuration creates an integrated development environment with a clear workflow progression:

**Terminal (zsh)** → **Session Management (tmux)** → **Code Editing (nvim)** → **Version Control (git)**

### 🐚 Terminal: Zsh with Powerlevel10k

**Theme**: Powerlevel10k lean style with 2-line prompt  
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
```

### 🖥️ Session Management: Tmux

**Prefix Key**: `Ctrl+a` (instead of default `Ctrl+b`)  
**Theme**: Gruvbox dark with visual prefix indicator

#### Key Features:
- **Prefix Indicator**: Shows `<Prefix>` in status bar when prefix is active
- **Vim-like Navigation**: hjkl for pane movement
- **Smart Splitting**: Maintains current directory when creating panes
- **Copy Mode**: System clipboard integration

#### Essential Keybindings:
| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix key |
| `Ctrl+a \|` | Split window vertically |
| `Ctrl+a -` | Split window horizontally |
| `Ctrl+a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+a H/J/K/L` | Resize panes |
| `Ctrl+a r` | Reload tmux config |
| `Ctrl+a Ctrl+a` | Quick pane cycling |

#### Copy Mode (Ctrl+a [):
| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `y` | Copy selection to system clipboard |
| `r` | Toggle rectangle selection |

### 🚀 Project Management

**Configuration**: `config/projects.nix`  
**Purpose**: Quick access to project workspaces with tmux sessions

#### Example Projects:
- **`website`**: Web project with code + content workflow  
- **`nix-config`**: System configuration with basic development workflow
- **`research-project`**: Academic project with code + paper workflow

#### Usage:
```bash
proj              # List all available projects
website           # Launch website project tmux session  
research-project  # Launch research project tmux session
nix-config        # Launch nix-config project tmux session
```

#### Template Types:
- **Basic**: Single directory (nvim + git + shell)
- **Research**: Code directory + separate paper directory + optional remote server

#### Research Template Remote Server Support:
The research template supports optional remote server connections:
- **Remote Server Window**: Dual horizontal panes for parallel remote work
- **Automatic Connection**: SSH to configured server with automatic directory navigation
- **Reconnect Alias**: Type `r` in any remote pane to easily reconnect

**Example Configuration:**
```nix
research-project = {
  template = "research";
  name = "Research Project";
  codePath = "~/Projects/research-code";
  paperPath = "~/Projects/research-paper";
  description = "Academic research project";
  server = "dev-server";        # SSH host from ~/.ssh/config  
  remoteDir = "~/research";     # Remote directory path
};
```

### 📝 Code Editing: Neovim

**Theme**: Gruvbox dark with hard contrast  
**Leader Key**: `<Space>`

#### Key Features:
- **File Explorer**: nvim-tree with dotfile filtering
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

**System Clipboard:**
| Key | Action |
|-----|--------|
| `<Space>y` | Copy to system clipboard |
| `<Space>p` | Paste from system clipboard |

**Git Operations:**
| Key | Action |
|-----|--------|
| `<Space>gs` | Git status |
| `<Space>gd` | Git diff |
| `<Space>gc` | Git commit |
| `<Space>gp` | Git push |

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

#### Git Visualization with lazygit
Launch `lazygit` in any git repository for:
- Interactive commit graph and branch visualization
- Streamlined staging, committing, and diff viewing
- Easy branch management and merging
- File tree navigation with git status

## 🔐 SSH Configuration

**Configuration**: `modules/ssh.nix`  
**Purpose**: Declarative SSH client configuration and host management

#### Key Features:
- **Declarative Hosts**: All SSH hosts defined in nix configuration
- **Version Controlled**: SSH config tracked with git alongside other configurations
- **Reproducible**: Same SSH setup deployable across multiple machines
- **Security**: Private keys remain local and untracked

#### Example Host Configuration:
- **dev-server**: Development server with proxy jump
- **storage**: Network storage server  
- **homelab**: Home server setup
- **cloud-vps**: Cloud VPS instance

#### Host Management:
Edit SSH hosts in `modules/ssh.nix`, then apply changes:
```bash
home-manager switch --flake .#yanlin
```

#### Security Best Practices:
- ✅ **SSH configuration**: Managed by nix (hosts, ports, usernames)
- ❌ **Private keys**: Keep local in `~/.ssh/keys/` (not tracked by nix)
- ❌ **known_hosts**: Generated locally (not synced)

## 🛠️ Development Tools

### Enhanced CLI Utilities

- **fzf**: Fuzzy finder for files, commands, and history with built-in zsh keybindings
- **fd**: Fast, user-friendly alternative to find
- **ripgrep (rg)**: Fast text search across codebases
- **bat**: Syntax-highlighted cat replacement with git integration
- **btop**: Modern system monitor with vim-like navigation
- **zoxide**: Smart cd replacement with frecency algorithm
- **httpie**: Modern HTTP client for API testing and development

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

## 🌟 Specialized Tools

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
pafile filename.pdf           # Add file from ~/Downloads/
paopen                        # Open documents interactively  
pafinder "query"              # Open document directory in Finder
patag "tag1#tag2" "query"     # Add multiple tags using # separator
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

## 💻 Machine Configurations

- **`iMac`**: iMac configuration
- **`MacBook-Air`**: MacBook Air configuration

Both machines use the same base configuration with potential for machine-specific customizations.

### Machine-specific Usage:
```bash
# For MacBook Air
sudo darwin-rebuild switch --flake .#MacBook-Air

# For iMac  
sudo darwin-rebuild switch --flake .#iMac
```

## 📦 Complete Package List

### Core Development Tools
- **Python 3.12** with uv package manager
- **LaTeX** (Full TeXLive distribution)
- **Claude Code** (AI-powered coding assistant)
- **Git** with comprehensive aliases and lazygit visualization

### CLI Utilities
- **fzf** (Fuzzy finder)
- **fd** (Fast file finding)  
- **ripgrep** (Fast text search)
- **bat** (Syntax-highlighted file viewing)
- **btop** (Modern system monitor)
- **zoxide** (Smart directory navigation)
- **httpie** (Modern HTTP client)

### Database & File Management
- **sqlite3** (SQLite command-line interface)
- **lazysql** (TUI database management)
- **rsync** (File synchronization and backup)
- **termscp** (Terminal file transfer client)  
- **lftp** (Scriptable FTP client)

### Academic & Documentation
- **papis** (Reference management system)

### Fonts
- **Nerd Fonts**: FiraCode and JetBrains Mono with icon support