{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../system-default.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  jovian.devices.steamdeck.enable = true;

  jovian.steam = {
    enable = true;
    autoStart = true;
    user = "yanlin";
  };

  jovian.steamos.useSteamOSConfig = true;

  jovian.hardware.has.amd.gpu = true;

  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "deck";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmKZ0FbXhYRHVkVTeSmpPrvuG8sC8La3Yx2gWb4ncuc yanlin@imac"
    ];
  };

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
  ];
}
