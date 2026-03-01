{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.zsh.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AcceptEnv = [ "LANG" "LC_*" "TERM" "COLORTERM" "TMUX" "TMUX_PANE" ];
    };
  };

  users.users.yanlin = {
    isNormalUser = true;
    description = "yanlin";
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    curl
  ];

  system.stateVersion = "24.05";
}
