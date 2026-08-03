# Custom Syncthing layer over the home-manager syncthing service.
# It records the device ids of the user's machines and exposes syncthing-custom.folders, so a host enables a shared folder by setting syncthing-custom.folders.<name>.enable = true.
# The declarative device and folder lists are authoritative, and a matching .stignore is written into each enabled folder on activation.

# NOTE: Obtain device id using command `syncthing device-id`

{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;

  deviceIds = {
    "sakurako" = {
      id = "XPAMYJX-D7UZKPI-JBLTAWG-EBPSFYV-NEFV42V-NIUZKQN-KTVTGGP-OOXL5AT";
    };
    "himawari" = {
      id = "2ST6EEF-KN3R2E6-PN64WAS-XGJ22NV-BAWAQX6-OCZLYE3-V5IM2SE-S22REAA";
    };
    "nadeshiko" = {
      id = "S4QZW76-BOLIOW7-DVP326F-JIGW5DW-3PAD47L-OA456LB-2L6JZW7-YUGJRA6";
    };
    "misaki" = {
      id = "D27MBZ3-IZXD5IE-WF5WZJE-4C4XNH3-PTHU5HP-QVEZYBX-UZ5OM2B-HK6LGQC";
    };
    # The Google Pixel, named after 小川こころ, the dreamy and unpredictable oddball of 大室花子's friends who hides surprising ability behind an airy manner.
    # Like her, this is the quirky odd one out of the fleet, the lone Android among the Apple phone and the Macs.
    "kokoro" = {
      id = "4ZKYD65-5KZUGTO-M5UMCC4-7ZVPUOC-HWXYIKD-XGNH75T-NCUDUGB-V2GT3AZ";
    };
    # The iPhone, named after 相馬未来, a cheerful and ordinary member of 大室花子's friends who never quite stands out.
    # Like her, this is a plain everyday phone that does nothing wrong and nothing remarkable.
    "mirai" = {
      id = "ZHPBZI7-7HUH52V-SM6U4N2-HLEEVHI-7BJV6YS-AZCY7KM-KWQB5JA-ITWTIAV";
    };
  };

  devices = lib.attrNames deviceIds;

  globalIgnore = [
    "node_modules" ".venv" "__pycache__" ".DS_Store" ".localized" ".thumbnails"
    ".obsidian/workspace.json" ".obsidian/workspace-mobile.json"
  ];

  # A folder path is stored as a literal "~/..." string, so expand it to $HOME at activation time when the .stignore file is written.
  shellPath = p:
    if lib.hasPrefix "~/" p
    then ''"$HOME"/'' + lib.escapeShellArg (lib.removePrefix "~/" p)
    else lib.escapeShellArg p;

  mkFolderOptions = name: overrides: let
    opts = {
      enable = { type = lib.types.bool; default = false; };
      path = { type = lib.types.str; default = "~/${name}"; };
      maxAgeDays = { type = lib.types.int; default = 0; };
      devices = { type = lib.types.listOf lib.types.str; default = devices; };
      ignore = { type = lib.types.listOf lib.types.str; default = []; };
    };
  in lib.mapAttrs (k: v: lib.mkOption {
    type = v.type;
    default = overrides.${k} or v.default;
  }) opts;

  mkVersioning = days:
    if days == 0 then {}
    else {
      versioning = {
        type = "staggered";
        params = {
          maxAge = toString (days * 86400);
          cleanInterval = "3600";
        };
      };
    };

in
{
  options.syncthing-custom = {
    folders = {
      Documents = mkFolderOptions "Documents" {};
    };
    enableGui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the Syncthing web GUI.";
    };
  };

  config = let
    enabled = lib.filterAttrs (_: f: f.enable) cfg.folders;
  in {
    services.syncthing = {
      enable = true;
      tray.enable = false;
      overrideDevices = true;
      overrideFolders = true;

      guiAddress = lib.mkIf cfg.enableGui "127.0.0.1:8384";

      settings = {
        devices = deviceIds;

        folders = lib.mapAttrs (_: f: {
          path = f.path;
          devices = f.devices;
        } // mkVersioning f.maxAgeDays) enabled;

        # The GUI binds to loopback only, so it runs without a password and skips the host check.
        gui = {
          enabled = cfg.enableGui;
          user = "yanlin";
          password = "";
          useTLS = false;
          insecureSkipHostcheck = true;
        };

        options = {
          # -1 declines Syncthing usage reporting.
          urAccepted = -1;
          relaysEnabled = true;
          localAnnounceEnabled = true;
          globalAnnounceEnabled = true;
        };
      };
    };

    home.activation.syncthingStignore = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStrings (lib.mapAttrsToList (name: f: ''
        folder=${shellPath f.path}
        if [ -d "$folder" ]; then
          printf '%s\n' ${lib.escapeShellArgs (globalIgnore ++ f.ignore)} > "$folder/.stignore"
        else
          echo "syncthing-custom: skipping .stignore for ${name} ($folder does not exist)"
        fi
      '') enabled)
    );
  };
}
