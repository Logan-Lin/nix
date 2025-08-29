{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Network and file transfer
    lftp
    termscp
    httpie
    openssh
    rsync
    gnumake
    
    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
  ];
}
