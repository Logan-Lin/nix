{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development and build tools
    texlive.combined.scheme-full
    python312
    uv
    gnumake
    
    # Network and file transfer
    lftp
    termscp
    httpie
    openssh
    rsync
    
    # Database and data tools
    lazysql
    sqlite
    papis
    
    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
    
    # Cross-platform applications
    keepassxc      # Password manager (Linux/Windows/macOS)
    syncthing      # File synchronization (cross-platform)
  ];
}
