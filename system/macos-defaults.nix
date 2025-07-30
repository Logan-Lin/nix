{ config, pkgs, ... }:

{
  system.defaults.NSGlobalDomain = {
    # Menu bar spacing configuration
    # NSStatusItemSpacing controls horizontal spacing between menu bar items
    # NSStatusItemSelectionPadding controls padding inside selection overlay
    # Optimal ratio is 1:2 (spacing:padding)
    NSStatusItemSpacing = 6;
    NSStatusItemSelectionPadding = 12;
  };
}