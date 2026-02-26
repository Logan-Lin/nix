{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/vpn/client.nix
    ../../../modules/podman.nix
    ../../../modules/borg/client.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 50;
    efi.canTouchEfiVariables = true;
    timeout = 3;
    grub.configurationLimit = 10;
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "i915.enable_psr=1"
    "i915.enable_fbc=1"
    "drm.debug=0"
  ];

  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];

  services.fwupd.enable = true;

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        vpl-gpu-rt
        intel-compute-runtime
      ];
    };

  };

  networking = {
    hostName = "thinkpad";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
    firewall.enable = false;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1100;
      INTEL_GPU_MAX_FREQ_ON_BAT = 900;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1100;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1100;
      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 100;
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };

  services.thermald.enable = true;

  services.thinkfan = {
    enable = true;
    levels = [
      [0  0   42]
      [1  40  47]
      [2  45  52]
      [3  50  57]
      [4  55  62]
      [5  60  72]
      [7  70  82]
      [127 80 32767]
    ];
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

  services.acpid.enable = true;

  services.wireguard-client = {
    enable = true;
    address = "10.2.2.20/24";
    serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
    serverEndpoint = "91.98.84.215:51820";
  };

  services.borg-client-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./thinkpad";
    backupPaths = [
      "/home/yanlin/Archive"
      "/home/yanlin/Credentials"
      "/home/yanlin/Documents"
      "/home/yanlin/Media"
      "/home/yanlin/.config/"
    ];
    backupFrequency = "*-*-* 00:00:00";
    checkFrequency = "Sun *-*-* 12:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
