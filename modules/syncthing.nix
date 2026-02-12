{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;

  pcDevices = [ "macbook" "imac" "thinkpad" "nfss" ];
  touchDevices = [ "iphone" "ipad" ];
  allDevices = pcDevices ++ touchDevices;

  mkFolderOptions = name: { maxAgeDays ? 0 }: {
    enable = lib.mkEnableOption "${name} folder" // { default = true; };
    path = lib.mkOption { type = lib.types.str; default = "~/${name}"; };
    maxAgeDays = lib.mkOption { type = lib.types.int; default = maxAgeDays; };
  };

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

  mkFolder = name: folderCfg: extraAttrs:
    lib.optionalAttrs folderCfg.enable {
      ${name} = {
        path = folderCfg.path;
        devices = extraAttrs.devices;
      } // mkVersioning folderCfg.maxAgeDays;
    };

in
{
  options.syncthing-custom = {
    folders = {
      Credentials = mkFolderOptions "Credentials" {};
      Documents = mkFolderOptions "Documents" {};
      Media = mkFolderOptions "Media" {};
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

        folders =
          mkFolder "Credentials" cfg.folders.Credentials { devices = allDevices; }
          // mkFolder "Documents" cfg.folders.Documents { devices = pcDevices; }
          // mkFolder "Media" cfg.folders.Media { devices = lib.filter (d: d != "iphone") allDevices; }
          // mkFolder "Archive" cfg.folders.Archive { devices = allDevices; };

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

    launchd.agents.syncthing = lib.mkIf (pkgs.stdenv.isDarwin && config.services.syncthing.enable) {
      config.RunAtLoad = true;
    };

    home.activation.reloadSyncthing = lib.mkIf (pkgs.stdenv.isDarwin && config.services.syncthing.enable) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD /bin/launchctl kickstart -k gui/$(id -u)/org.nix-community.home.syncthing || true
      ''
    );
  };
}
