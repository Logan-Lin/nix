{ config, pkgs, ... }:

{
  # Key remapping using hidutil via launchd agent
  # This swaps Control and Caps Lock keys bidirectionally
  
  launchd.user.agents.remap-keys = {
    serviceConfig = {
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},{"HIDKeyboardModifierMappingSrc":0x7000000E0,"HIDKeyboardModifierMappingDst":0x700000039}]}''
      ];
      RunAtLoad = true;
      KeepAlive = false;
      Label = "org.nixos.remap-keys";
      StandardErrorPath = "/tmp/remap-keys.err";
      StandardOutPath = "/tmp/remap-keys.out";
    };
  };
}