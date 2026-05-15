{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../system-default.nix
    ../../../modules/vpn/client.nix
    ../../../modules/hyprland/system.nix
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
    hostName = "thinkpad";
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
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_BOOST_ON_AC = 0;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 0;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    CPU_MAX_PERF_ON_AC = 80;
    CPU_MAX_PERF_ON_BAT = 40;
    PLATFORM_PROFILE_ON_AC = "balanced";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    INTEL_GPU_MIN_FREQ_ON_AC = 300;
    INTEL_GPU_MIN_FREQ_ON_BAT = 300;
    INTEL_GPU_MAX_FREQ_ON_AC = 800;
    INTEL_GPU_MAX_FREQ_ON_BAT = 700;
    INTEL_GPU_BOOST_FREQ_ON_AC = 900;
    INTEL_GPU_BOOST_FREQ_ON_BAT = 800;
    START_CHARGE_THRESH_BAT0 = 80;
    STOP_CHARGE_THRESH_BAT0 = 100;
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    HandlePowerKey = "suspend";
    HandleSuspendKey = "suspend";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };

  services.thermald.enable = true;

  services.thinkfan = {
    enable = true;
    levels = [
      [0   0   65]
      [1   60  78]
      [2   72  85]
      [3   80  90]
      [4   86  94]
      [7   91  97]
      [127 94  32767]
    ];
  };

  services.acpid.enable = true;

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "leftcontrol";
        rightcontrol = "capslock";
      };
    };
  };

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
}
