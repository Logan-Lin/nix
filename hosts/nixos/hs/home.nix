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
    interval = "*-*-* 19:00:00";
    randomDelay = "1h";
    commands = [
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@KitbogaShow/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@JCS/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@Shane_McGillicuddy/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@Coffeezilla/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@Danny-Gonzalez/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@StuffMadeHere/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@DankPods/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@ScottTheWoz/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@BeccaFarsace/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@WolfgangsChannel/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@DoshDoshington/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@salmence100/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@thespiffingbrit/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@LetsGameItOut/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@linustechtips/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@_gerg/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@Yeah_Jaron/videos'"
      "dlv bilibili -n 3 --days 7 -r 1 --title '摸鱼切片' 'https://space.bilibili.com/15810/upload/video'"  # Mr.Quin
      "dlv bilibili -n 3 --days 7 -r 1 --title 'PGN' 'https://space.bilibili.com/8012266/upload/video'"  # PGN
      "dlv bilibili -n 3 --days 7 -r 1 'https://space.bilibili.com/2799050'"  # 白洋
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/781973/lists/1035653?type=season'"  # 兰柚梓
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/387087193/lists/518549?type=season'"  # 平安Draymond
      "dlv-remove-older --days 14 '/mnt/storage/Media/web/'"
    ];
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
