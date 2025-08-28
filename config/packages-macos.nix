{ pkgs, claude-code, ... }:

{
  home.packages = with pkgs; [
    # macOS-specific GUI applications
    maccy          # Clipboard manager (macOS-only)
    appcleaner     # Application uninstaller (macOS-only)
    iina           # Media player (macOS-optimized)
    hidden-bar     # Menu bar organizer (macOS-only)

    # Tools
    claude-code.packages.aarch64-darwin.claude-code
  ];
}
