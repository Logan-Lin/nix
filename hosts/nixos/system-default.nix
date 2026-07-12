{ config, pkgs, inputs, ... }:

{
  imports = [
    ../system-default.nix
    inputs.disko.nixosModules.disko
  ];

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

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

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  environment.systemPackages = with pkgs; [
    vim
    curl
  ];

  system.stateVersion = "24.05";
}
