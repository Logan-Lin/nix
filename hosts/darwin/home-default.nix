{ config, pkgs, nixvim, claude-code, firefox-addons, ... }:

{
  imports = [ 
    nixvim.homeModules.nixvim
    ../../modules/nvim.nix 
    ../../modules/tmux.nix 
    ../../modules/zsh.nix 
    ../../modules/ssh.nix
    ../../modules/git.nix
    ../../modules/lazygit.nix
    ../../modules/papis.nix
    ../../modules/termscp.nix
    ../../modules/rsync.nix
    ../../modules/btop.nix
    ../../modules/firefox.nix
    ../../modules/ghostty.nix
    ../../modules/syncthing.nix
    ../../modules/dictionary.nix
    ../../config/fonts.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = "yanlin";
  home.homeDirectory = "/Users/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # darwin-specific alias
  programs.zsh.shellAliases = {
      oss = "sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)";

      preview = "open -a Preview";
      slide = "open -a SlidePilot";
      inkscape = "open -a Inkscape";
  };

  # Darwin-specific zsh functions
  programs.zsh.initContent = ''
    # Function to search and open all macOS applications
    function app() {
      local app_path
      local file_to_open="$1"
      
      app_path=$( (find -L /Applications -name "*.app" -maxdepth 2 2>/dev/null; \
                   find -L ~/Applications -name "*.app" -maxdepth 3 2>/dev/null; \
                   find /System/Applications -name "*.app" -maxdepth 2 2>/dev/null; \
                   find /System/Applications/Utilities -name "*.app" -maxdepth 1 2>/dev/null) | 
        sort | uniq | 
        fzf --header="Select app to open''${file_to_open:+ file: $file_to_open}" \
            --preview 'basename {} .app' \
            --preview-window=up:1 \
            --height=40%)
      
      if [[ -n "$app_path" ]]; then
        if [[ -n "$file_to_open" ]]; then
          open -a "$app_path" "$file_to_open"
        else
          open "$app_path"
        fi
      fi
    }
  '';

  home.packages = with pkgs; [
    # Network and file transfer
    lftp
    httpie
    openssh
    gnumake
    
    # Network diagnostic tools
    bind           # DNS utilities (dig, nslookup, mdig)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility
    curl           # HTTP client
    wget           # Web downloader
    
    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
    fastfetch

    # macOS-specific GUI applications
    maccy          # Clipboard manager (macOS-only)
    iina           # Media player (macOS-optimized)
    hidden-bar     # Menu bar organizer (macOS-only)

    # Development and build tools
    texlive.combined.scheme-full
    python312
    uv
    claude-code.packages.aarch64-darwin.claude-code
    lazysql
    sqlite

    # Productivity apps
    keepassxc      # Password manager (Linux/Windows/macOS)
  ];
}
