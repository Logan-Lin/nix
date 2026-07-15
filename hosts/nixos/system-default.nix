# NixOS platform default for the system configuration.
# Imports the cross-platform system default and disko, then layers on the settings shared by all NixOS hosts, such as SSH access, the primary user, and Tailscale networking.

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

  # NOTE: auth key file at: `/var/lib/tailscale/authkey` with mode 600
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/lib/tailscale/authkey";
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  environment.systemPackages = with pkgs; [
    vim
    curl
  ];

  system.stateVersion = "24.05";
}
