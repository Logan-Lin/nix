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
├── nvim.nix           # Neovim configuration with plugins and keymaps
├── tmux.nix           # Tmux setup with vim-like navigation
├── zsh.nix            # Zsh with Powerlevel10k and modern CLI tools
├── p10k.zsh           # Powerlevel10k theme configuration (managed by Nix)
└── tmux.sh            # Tmux session automation script
```

## 🛠️ Software Configurations

### 📝 Neovim

**Theme**: Gruvbox dark with hard contrast
**Leader Key**: `<Space>`

#### Key Features:
- **File Explorer**: nvim-tree with dotfile filtering
- **Syntax Highlighting**: Treesitter with all grammar support
- **Git Integration**: vim-fugitive for git operations
- **Status Line**: lualine with gruvbox theme and relative paths
- **System Clipboard**: Seamless integration for copy/paste

#### Keybindings:

| Key | Mode | Action |
|-----|------|--------|
| `<Space>e` | Normal | Toggle file explorer |
| `<Space>w` | Normal | Save file |
| `<Space>q` | Normal | Quit |
| `<Space>y` | Normal/Visual | Copy to system clipboard |
| `<Space>p` | Normal/Visual | Paste from system clipboard |
| `<Space>gs` | Normal | Git status |
| `<Space>gd` | Normal | Git diff |
| `<Space>gc` | Normal | Git commit |
| `<Space>gp` | Normal | Git push |

### 🖥️ Tmux

**Prefix Key**: `Ctrl+a` (instead of default `Ctrl+b`)
**Theme**: Gruvbox dark with visual prefix indicator

#### Key Features:
- **Prefix Indicator**: Shows `<Prefix>` in status bar when prefix is active
- **Vim-like Navigation**: hjkl for pane movement
- **Smart Splitting**: Maintains current directory when creating panes
- **Copy Mode**: System clipboard integration with pbcopy

#### Keybindings:

| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix key |
| `Ctrl+a |` | Split window vertically |
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

### 🐚 Zsh with Powerlevel10k

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

#### Vim Mode Keybindings:
| Key | Mode | Action |
|-----|------|--------|
| `Esc` | Insert | Switch to normal mode |
| `i/a/I/A` | Normal | Switch to insert mode |
| `k/j` | Normal | History search backward/forward |
| `/` | Normal | History incremental search backward |
| `?` | Normal | History incremental search forward |
| `Ctrl+Right/Left` | Insert | Word movement |

#### Aliases:

**Navigation:**
```bash
l, ll, la          # Enhanced ls commands
.., ..., ....      # Quick directory navigation
home, config       # Jump to common directories
nix-config         # Jump to nix configuration
```

**Git:**
```bash
g, gs, ga, gc, gp, gl, gd, gco, gb  # Git shortcuts
glog               # Beautiful git log with graph
```

**Modern CLI:**
```bash
cat → bat          # Syntax highlighted file viewing
find → fd          # Fast file finding
grep → rg          # Ripgrep for fast searching
top → btop         # Beautiful system monitor
```

**Nix:**
```bash
hm                 # home-manager shortcut
hms                # Quick home-manager switch
```

### 🌟 Git Visualization

**Tool**: gitui
**Purpose**: Beautiful, interactive TUI for git operations

Launch with `gitui` in any git repository for:
- Interactive commit graph visualization
- Diff viewing and staging
- Branch management
- Vim-like navigation (j/k for movement, h/l for tabs)

## 📦 Included Packages

### Development Tools
- **Python 3.12**: With pip and virtualenv
- **LaTeX**: Full TeXLive distribution
- **Claude Code**: AI-powered coding assistant
- **Git UI**: Beautiful git graph visualization

### CLI Utilities
- **fzf**: Fuzzy finder for files, commands, and history
- **fd**: Fast, user-friendly alternative to find
- **ripgrep (rg)**: Fast text search
- **bat**: Syntax-highlighted cat replacement
- **btop**: Modern system monitor
- **zoxide**: Smart cd with frecency algorithm

#### fd Usage Examples
```bash
fd filename          # Find files/directories named "filename"
fd "*.nix"          # Find all Nix files
fd -t f config      # Only files (-t f = type file)
fd -t d config      # Only directories (-t d = type directory)
fd -e js            # All files with .js extension
fd -H hidden        # Include hidden files (-H)
fd | fzf            # Pipe to fzf for interactive selection
```

### Fonts
- **Nerd Fonts**: FiraCode and JetBrains Mono with icon support

## 🔄 Usage & Workflow

### Daily Workflow
1. **Terminal**: Beautiful zsh with vim mode and modern tools
2. **Tmux**: Session management with vim navigation
3. **Neovim**: Code editing with git integration
4. **Git UI**: Visual git operations and branch management

### Environment Management
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

### Clipboard Integration
The configuration provides seamless clipboard integration:
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

