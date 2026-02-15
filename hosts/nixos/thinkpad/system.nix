{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/podman.nix
    ../../../modules/vpn/tailscale.nix
    ../../../modules/borg/client.nix
  ];

  # Bootloader - standard UEFI setup
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

  # Use latest kernel for better hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters for ThinkPad
  boot.kernelParams = [
    "i915.enable_psr=1"
    "i915.enable_fbc=1"
    "drm.debug=0"
  ];

  # Blacklist NVIDIA kernel modules to disable discrete GPU completely
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];

  # Enable firmware updates
  services.fwupd.enable = true;

  # Hardware support for ThinkPad P14s Gen 2 Intel (Intel graphics only)
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    
    # Graphics configuration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver  # LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but sometimes works better)
        libva-vdpau-driver
        libvdpau-va-gl
        vpl-gpu-rt
        intel-compute-runtime
      ];
    };

  };

  # Network configuration
  networking = {
    hostName = "thinkpad";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
    firewall.enable = false;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # Power management for laptops
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # TLP for advanced power management
  services.power-profiles-daemon.enable = false; # Conflicts with TLP
  services.tlp = {
    enable = true;
    settings = {
      # CPU power management
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Intel GPU power management
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1100;
      INTEL_GPU_MAX_FREQ_ON_BAT = 900;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1100;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1100;
      
      # ThinkPad battery charge thresholds (preserve battery health)
      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 100;
      
      # PCIe power management
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      
      # Keep Bluetooth available on battery
      # DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
    };
  };

  # Disable all suspend/sleep for headless server operation
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };

  # Thermal management
  services.thermald.enable = true;

  # ThinkPad specific: thinkfan for better fan control
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

  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "no";  # Disable root login for laptop
    };
  };

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    hashedPassword = "$6$kSyaRzAtj8VPcNeX$NsEP6zQAfp6O8YWcolfPRKnhIcJlKu5luZgWqozJAHtbE/gv90KoOOKU7Dt.FnbPB0Ej26jXoBH4X.7y/OLGB1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICp2goZiuSfwMA02GsHhYzUZHrQPPBgP5sWSNP9kQR3e yanlin@imac"
    ];
  };

  services.keyd = {
    enable = true;
    keyboards = {
      internal = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "leftcontrol";
            leftalt = "leftmeta";
          };
        };
      };
    };
  };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils

    # GPU monitoring
    intel-gpu-tools

    # ThinkPad specific
    lm_sensors  # Temperature monitoring
    smartmontools  # Disk health monitoring (SMART)
  ];


  services.acpid.enable = true;

  services.tailscale-custom.exitNode = true;

  services.borg-client-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./thinkpad";
    backupPaths = [
      "/home/yanlin/Archive"
      "/home/yanlin/Credentials"
      "/home/yanlin/Documents"
      "/home/yanlin/Media"
      "/home/yanlin/DCIM"
    ];
    backupFrequency = "*-*-* 00:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
