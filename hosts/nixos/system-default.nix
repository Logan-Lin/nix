{ config, pkgs, ... }:

{
  # Common NixOS system configuration shared across all hosts

  # Time zone and localization
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable zsh system-wide (required when set as user shell)
  programs.zsh.enable = true;

  # Enable bandwhich network monitoring tool
  programs.bandwhich.enable = true;

  # Enable experimental nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Basic SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AcceptEnv = "LANG LC_* TERM COLORTERM TMUX TMUX_PANE";
    };
  };

  # Common user configuration
  users.users.yanlin = {
    isNormalUser = true;
    description = "yanlin";
    shell = pkgs.zsh;
  };

  # Enable sudo for wheel group without password
  security.sudo.wheelNeedsPassword = false;

  # Common system packages
  environment.systemPackages = with pkgs; [
    # Essential command-line tools
    vim
    git
    htop
    curl
    wget
    rsync
    tmux
    tree
    lsof
    tcpdump
    iotop
    
    # Shell and system management
    zsh
    home-manager
  ];

  # Default system state version
  system.stateVersion = "24.05";
}