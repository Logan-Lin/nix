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
    downloadDir = "/mnt/storage/Media/web";
    subscriptions = {
      enable = true;
      feeds = [
        # Example feed - replace with your actual subscriptions
        "https://www.youtube.com/feeds/videos.xml?channel_id=UCovVc-qqwYp8oqwO3Sdzx7w"
      ];
      maxVideosPerFeed = 1; # Start with just 3 videos per feed for testing
    };
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
  ];
  
}
