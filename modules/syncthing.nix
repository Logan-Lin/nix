{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;
  
  pcDevices = [ "macbook" "imac" "thinkpad" "nfss" ];
  touchDevices = [ "iphone" "ipad" ];
  allDevices = pcDevices ++ touchDevices;

  commonVersioning = {
    type = "staggered";
    params = {
      maxAge = "15552000"; # 180 days
      cleanInterval = "3600";  # 1 hour
    };
  };

  liteVersioning = {
    type = "staggered";
    params = {
      maxAge = "2592000"; # 30 days
      cleanInterval = "3600";
    };
  };

in
{
  options.syncthing-custom = {
    enabledFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "Credentials" "Documents" "Archive" "Media" ];
      description = "List of Syncthing folders to enable for this host.";
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
          (lib.optionalAttrs (lib.elem "Credentials" cfg.enabledFolders) {
            "Credentials" = {
              path = "~/Credentials";
              devices = allDevices;
              versioning = commonVersioning;
            };
          })
          // (lib.optionalAttrs (lib.elem "Documents" cfg.enabledFolders) {
            "Documents" = {
              path = "~/Documents";
              devices = pcDevices;
              versioning = commonVersioning;
            };
          })
          // (lib.optionalAttrs (lib.elem "Media" cfg.enabledFolders) {
            "Media" = {
              path = "~/Media";
              devices = lib.filter (d: d != "iphone") allDevices;
              versioning = liteVersioning;
            };
          })
          // (lib.optionalAttrs (lib.elem "Archive" cfg.enabledFolders) {
            "Archive" = {
              path = "~/Archive";
              devices = allDevices;
              versioning = commonVersioning;
            };
          });
        
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
