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
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@KitbogaShow/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@JCS/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@Shane_McGillicuddy/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@Coffeezilla/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@Danny-Gonzalez/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@rejectconvenience/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@StuffMadeHere/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@AdamSomething/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@_gerg/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@Yeah_Jaron/videos'"
      "dl-yt -n 3 -r 1 'https://www.youtube.com/@WolfgangsChannel/videos'"
    ];
  };
  
  programs.zsh.shellAliases = {
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };

  home.packages = with pkgs; [
  ];
  
}
