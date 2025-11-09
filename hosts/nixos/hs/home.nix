{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/schedule.nix
  ];

  # hs-specific home configuration
  
  # yt-dlp configuration - store videos on large storage
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "/mnt/storage/Media/web";
  };

  services.scheduled-commands.video-downloads = {
    enable = true;
    description = "Download web videos from favorite channels";
    interval = "*-*-* 08:00:00";
    randomDelay = "1h";
    commands = [
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@KitbogaShow/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@JCS/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@Shane_McGillicuddy/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@Coffeezilla/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@Danny-Gonzalez/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@StuffMadeHere/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@DankPods/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@ScottTheWoz/videos'"
      "dlv youtube -n 3 -r 1 --min 1 --max 180 'https://www.youtube.com/@thespiffingbrit/videos'"
      "dlv bilibili -n 3 -r 1 --title '摸鱼切片' 'https://space.bilibili.com/15810/upload/video'"  # Mr.Quin
      "dlv bilibili -n 3 -r 1 -p 'https://space.bilibili.com/8012266/lists/3844977?type=season'"  # PGN
    ];
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
