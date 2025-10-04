{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/scheduled-commands.nix
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
      "dl-yt -n 3 https://www.youtube.com/@KitbogaShow"
      "dl-yt -n 3 https://www.youtube.com/@JCS"
      "dl-yt -n 3 https://www.youtube.com/@Shane_McGillicuddy"
      "dl-yt -n 3 https://www.youtube.com/@Coffeezilla"
      "dl-yt -n 3 https://www.youtube.com/@Danny-Gonzalez"
      "dl-yt -n 3 https://www.youtube.com/@rejectconvenience"
      "dl-yt -n 3 https://www.youtube.com/@StuffMadeHere"
      "dl-yt -n 3 https://www.youtube.com/@AdamSomething"
      "dl-yt -n 3 https://www.youtube.com/@_gerg"
      "dl-yt -n 3 https://www.youtube.com/@Yeah_Jaron"
      "dl-yt -n 3 https://www.youtube.com/@WolfgangsChannel"
    ];
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
