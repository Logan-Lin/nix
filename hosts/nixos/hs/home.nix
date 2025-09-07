{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
  ];

  # hs-specific home configuration
  programs.zsh.shellAliases = {
      # Disk health monitoring
      smart-report = "sudo /home/yanlin/.config/nix/scripts/daily-smart-report.sh";
      move-inbox = "cp -rl /mnt/storage/Media/downloads/.inbox/* /mnt/storage/Media/downloads/inbox && chown -R yanlin:users /mnt/storage/Media/downloads/inbox";
  };
  
}
