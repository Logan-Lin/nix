{ config, pkgs, ... }:

{
  imports = [
    ../../modules/homebrew.nix
  ];

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
