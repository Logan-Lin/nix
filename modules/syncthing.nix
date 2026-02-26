# NOTE: Obtain device id using command `syncthing device-id`
# Add the device under `config.settings.devices`

{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;

  pcDevices = [ "macbook" "imac" ];
  serverDevices = [ "thinkpad" "nfss" ];
  touchDevices = [ "iphone" "ipad" ];
  allDevices = pcDevices ++ serverDevices ++ touchDevices;

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
      Credentials = mkFolderOptions "Credentials" {};
      Documents = mkFolderOptions "Documents" { devices = pcDevices ++ serverDevices; };
      Media = mkFolderOptions "Media" { devices = serverDevices ++ [ "ipad" ]; };
      Archive = mkFolderOptions "Archive" {};
    };
    enableGui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the Syncthing web GUI.";
    };
  };

  config = {
    services.syncthing = {
      enable = true;
      tray.enable = false;
      overrideDevices = true;
      overrideFolders = true;

      guiAddress = lib.mkIf cfg.enableGui "127.0.0.1:8384";

      settings = {
        devices = {
          "iphone" = {
            id = "NMWI5MP-J4FC4A6-SDDXZPD-G66TJCO-2W7KGFD-RJWQ53U-I7GUVWP-WHF4QQO";
          };
          "thinkpad" = {
            id = "OMZKASU-QPZDCQ2-7QRHRD4-3TPAXLM-AYRMWXB-A6E5OIZ-MGR422V-JYARQA6";
          };
          "ipad" = {
            id = "ZN3W6K7-VTRRRMT-Y35PSVU-EARJ6FP-6JBFIOF-YAFUAUZ-2TSFW3T-5YGDZAO";
          };
          "macbook" = {
            id = "XPAMYJX-D7UZKPI-JBLTAWG-EBPSFYV-NEFV42V-NIUZKQN-KTVTGGP-OOXL5AT";
          };
          "imac" = {
            id = "2ST6EEF-KN3R2E6-PN64WAS-XGJ22NV-BAWAQX6-OCZLYE3-V5IM2SE-S22REAA";
          };
          "nfss" = {
            id = "S4QZW76-BOLIOW7-DVP326F-JIGW5DW-3PAD47L-OA456LB-2L6JZW7-YUGJRA6";
          };
        };

        folders = let
          enabled = lib.filterAttrs (_: f: f.enable) cfg.folders;
        in lib.mapAttrs (_: f: {
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

  };
}
