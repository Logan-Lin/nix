# NOTE: Obtain device id using command `syncthing device-id`
# Add the device under `config.settings.devices`

{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;

  pcDevices = [ "misaki" "sakurako" "himawari" ];
  serverDevices = [ "nadeshiko" ];
  touchDevices = [ "mirai" ];
  allDevices = pcDevices ++ serverDevices ++ touchDevices;

  ignorePatterns = [ "node_modules" ".venv" ".direnv" "__pycache__" ".DS_Store" ".localized" ];

  shellPath = p:
    if lib.hasPrefix "~/" p
    then ''"$HOME"/'' + lib.escapeShellArg (lib.removePrefix "~/" p)
    else lib.escapeShellArg p;

  mkFolderOptions = name: overrides: let
    opts = {
      enable = { type = lib.types.bool; default = false; };
      path = { type = lib.types.str; default = "~/${name}"; };
      maxAgeDays = { type = lib.types.int; default = 0; };
      devices = { type = lib.types.listOf lib.types.str; default = allDevices; };
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
        devices = {
          "mirai" = {
            id = "NMWI5MP-J4FC4A6-SDDXZPD-G66TJCO-2W7KGFD-RJWQ53U-I7GUVWP-WHF4QQO";
          };
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
        };

        folders = lib.mapAttrs (_: f: {
          path = f.path;
          devices = f.devices;
        } // mkVersioning f.maxAgeDays) enabled;

        gui = {
          enabled = cfg.enableGui;
          user = "yanlin";
          password = "";
          useTLS = false;
          insecureSkipHostcheck = true;
        };

        options = {
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
          printf '%s\n' ${lib.escapeShellArgs ignorePatterns} > "$folder/.stignore"
        else
          echo "syncthing-custom: skipping .stignore for ${name} ($folder does not exist)"
        fi
      '') enabled)
    );
  };
}
