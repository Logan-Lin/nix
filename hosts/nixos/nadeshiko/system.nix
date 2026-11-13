# nadeshiko is a Framework Laptop 13 with an AMD Ryzen AI 5 340, running the Hyprland Wayland desktop.

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../system-default.nix
    ../../../modules/hyprland/system.nix
    "${inputs.nixos-hardware}/framework/13-inch/amd-ai-300-series"
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "nadeshiko";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # 22000 and 21027 for Syncthing.
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 21027 22000 ];
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # nixos-hardware enables fprintd, which adds fingerprint authentication to every PAM service by default.
  # Keep the greeter on password login so it can unlock the GNOME keyring.
  # hyprlock talks to fprintd on its own, so its PAM service stays on password only.
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.hyprlock.fprintAuth = false;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = "suspend-then-hibernate";
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  services.openssh = {
    settings = {
      PermitRootLogin = "no";
    };
  };

  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    hashedPassword = "$6$4tNeZ9/B3SSapStU$vX1pco.IuMMu/AcLeGvZoOGxSNNlorVdnRGSVFIWou5ybcpwxrJHAFqvKpJiObejHe2sy7CnJ8fiMACaTwDN5/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERRkvPmN1fWEwJQZ83sYrfpSRwq492i+LjLySjXiGsL yanlin@nadeshiko"
    ];
  };

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    lm_sensors
  ];
}
