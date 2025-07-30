{ config, pkgs, ... }:

{
  # Set primary user for system preferences
  system.primaryUser = "yanlin";
  
  # Menu bar spacing configuration using activation scripts
  # Uses -currentHost to write host-specific preferences
  # NSStatusItemSpacing controls horizontal spacing between menu bar items
  # NSStatusItemSelectionPadding controls padding inside selection overlay
  system.activationScripts.postUserActivation.text = ''
    echo "Setting menu bar spacing preferences..."
    defaults -currentHost write -globalDomain NSStatusItemSpacing -int 12
    defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6
  '';
}
