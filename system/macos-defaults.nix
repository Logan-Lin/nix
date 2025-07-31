{ config, pkgs, ... }:

{
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
  '';
}
