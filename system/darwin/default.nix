{ config, pkgs, nix-homebrew, ... }:

{
  imports = [
    ../../modules/homebrew.nix
    nix-homebrew.darwinModules.nix-homebrew
    ../../modules/tailscale.nix
  ];

  # Nix configuration
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];
  
  # System configuration
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  programs.zsh.enable = true;

  # Set primary user for system preferences
  system.primaryUser = "yanlin";
  
  # Menu bar spacing configuration using activation scripts
  # Uses sudo to run as user since activation now runs as root
  # NSStatusItemSpacing controls horizontal spacing between menu bar items
  # NSStatusItemSelectionPadding controls padding inside selection overlay
  system.activationScripts.extraActivation.text = ''
    echo "Setting menu bar spacing preferences..."
    sudo -u yanlin defaults -currentHost write -globalDomain NSStatusItemSpacing -int 10
    sudo -u yanlin defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 5
    
    echo "Disabling Spotlight indexing..."
    # Disable Spotlight indexing for all volumes
    # WARNING: This will break Mail.app search, Time Machine, and other features
    # To re-enable: sudo mdutil -a -i on
    sudo mdutil -a -i off
    
    # Erase existing Spotlight index to free up disk space
    echo "Erasing existing Spotlight index..."
    sudo mdutil -E /
  '';
}
