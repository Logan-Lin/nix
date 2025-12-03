{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/schedule.nix
    ../../../modules/yt-dlp.nix
  ];

  # hs-specific home configuration

  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup aicloud files";
    interval = "*-*-* 18:00:00";
    commands = [
      "rsync -avP aicloud:~/ /mnt/storage/Backup/aicloud/ --exclude='/.*'"
    ];
  };
  
  # yt-dlp configuration - store videos on large storage
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "/mnt/storage/Media/web";
  };

  services.scheduled-commands.video-downloads = {
    enable = true;
    description = "Download web videos from favorite channels";
    interval = "*-*-* 06,18:00:00";
    randomDelay = "15m";
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
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@DigitalFoundry/videos'"
      "dlv youtube -n 3 --days 7 -r 1 --min 1 --max 180 'https://www.youtube.com/@mkbhd/videos'"
      "dlv-remove-older --days 30 '/mnt/storage/Media/web/YouTube'"
      "dlv bilibili -n 7 --days 7 -r 1 'https://space.bilibili.com/1629347259/upload/video'"  # 红警HBK08
      "dlv bilibili -n 7 --days 7 -r 1 'https://space.bilibili.com/483246073/upload/video'"  # 红警魔鬼蓝天
      "dlv bilibili -n 3 --days 7 -r 1 --title '摸鱼切片' 'https://space.bilibili.com/15810/upload/video'"  # Mr.Quin
      "dlv bilibili -n 3 --days 7 -r 1 --title 'PGN' 'https://space.bilibili.com/8012266/upload/video'"  # PGN
      "dlv bilibili -n 3 --days 7 -r 1 'https://space.bilibili.com/2799050'"  # 白洋
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/781973/lists/1035653?type=season'"  # 兰柚梓
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/781973/lists/2266217?type=season'"  # 兰柚梓
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/387087193/lists/518549?type=season'"  # 平安Draymond
      "dlv bilibili --days 7 -r 1 -p 'https://space.bilibili.com/24956505/lists/6741234?type=season'"  # 苦命亦云
      "dlv-remove-older --days 30 '/mnt/storage/Media/web/Bilibili'"
    ];
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
