{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
  ];

  # hs-specific home configuration
  
  # yt-dlp configuration - store videos on large storage
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "/mnt/storage/Media/Web";
  };
  
  programs.zsh.shellAliases = {
      # Disk health monitoring
      smart-report = "sudo SMART_DRIVES='/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R:ZFS_Mirror_1;/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG:ZFS_Mirror_2;/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB:Data_Drive_1_12TB;/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE:Data_Drive_2_12TB;/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE:Parity_Drive_16TB' /home/yanlin/.config/nix/scripts/daily-smart-report.sh Ac9qKFH5cA.7Yly";
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
  ];
  
}
