{ pkgs, ... }:

{
  home.packages = with pkgs; [
    papis
    keepassxc      # Password manager (Linux/Windows/macOS)
    syncthing      # File synchronization (cross-platform)
  ];
}
