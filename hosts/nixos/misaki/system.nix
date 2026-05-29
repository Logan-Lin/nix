{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../system-default.nix
    ../../../modules/vpn/nixos-client.nix
    ../../../modules/vpn/nixos-tunnel.nix
    ../../../modules/hyprland/system.nix
    ../../../modules/disk-health.nix
    "${inputs.nixos-hardware}/lenovo/thinkpad/p14s"
    "${inputs.nixos-hardware}/common/cpu/intel/tiger-lake"
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 50;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];

  services.fwupd.enable = true;

  hardware.graphics.enable = true;

  networking = {
    hostName = "misaki";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
    firewall.enable = false;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  powerManagement.powertop.enable = true;

  services.power-profiles-daemon.enable = false;
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MAX_PERF_ON_BAT = 100;
    PLATFORM_PROFILE_ON_AC = "balanced";
    PLATFORM_PROFILE_ON_BAT = "balanced";
    INTEL_GPU_MIN_FREQ_ON_AC = 300;
    INTEL_GPU_MIN_FREQ_ON_BAT = 300;
    INTEL_GPU_MAX_FREQ_ON_AC = 1000;
    INTEL_GPU_MAX_FREQ_ON_BAT = 900;
    INTEL_GPU_BOOST_FREQ_ON_AC = 1200;
    INTEL_GPU_BOOST_FREQ_ON_BAT = 1100;
    START_CHARGE_THRESH_BAT0 = 80;
    STOP_CHARGE_THRESH_BAT0 = 100;
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend-then-hibernate";
    HandleSuspendKey = "suspend-then-hibernate";
    HandleHibernateKey = "suspend-then-hibernate";
    IdleAction = "ignore";
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";

  services.thermald.enable = true;

  services.thinkfan = {
    enable = true;
    levels = [
      [0 0  60]
      [1 55 88]
      [2 85 93]
      [3 91 96]
      [4 94 98]
      [5 96 99]
      [6 98 100]
      [7 99 32767]
    ];
  };

  services.acpid.enable = true;

  services.journald.extraConfig = "SystemMaxUse=5G";

  services.openssh = {
    settings = {
      PermitRootLogin = "no";
    };
  };

  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    hashedPassword = "$6$4tNeZ9/B3SSapStU$vX1pco.IuMMu/AcLeGvZoOGxSNNlorVdnRGSVFIWou5ybcpwxrJHAFqvKpJiObejHe2sy7CnJ8fiMACaTwDN5/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICp2goZiuSfwMA02GsHhYzUZHrQPPBgP5sWSNP9kQR3e yanlin@imac"
    ];
  };

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    intel-gpu-tools
    lm_sensors
    smartmontools
  ];

  services.wireguard-client = {
    enable = true;
    address = "10.2.2.20/24";
    serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
    serverEndpoint = "91.98.84.215:51820";
  };

  services.disk-health = {
    enable = true;
    devices = [ "/dev/nvme0n1" ];
  };
}
