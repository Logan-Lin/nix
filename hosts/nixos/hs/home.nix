{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
  ];

  # hs-specific home configuration
  
  # yt-dlp configuration - store videos on large storage
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "/mnt/storage/Media/web";
    subscriptions = {
      enable = true;
      feeds = [
        "https://www.youtube.com/feeds/videos.xml?channel_id=UCm22FAXZMw1BaWeFszZxUKw"
        "https://www.youtube.com/feeds/videos.xml?channel_id=UCYwVxWpjeKFWwu8TML-Te9A"
        "https://www.youtube.com/feeds/videos.xml?channel_id=UCPJVs54XcE8RrdA_uW-lfUw"
      ];
      interval = "*-*-* 08:00:00";
      randomDelay = "1h";
      maxVideosPerFeed = 5;
    };
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
