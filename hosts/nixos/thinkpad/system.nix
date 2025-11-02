{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../system-default.nix  # Common NixOS system configuration
    ../../../modules/desktop.nix
    ../../../modules/wireguard.nix
    ../../../modules/login-display.nix
    ../../../modules/disable-keyboard.nix
  ];

  # Bootloader - standard UEFI setup
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 50;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Use latest kernel for better hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters for ThinkPad
  boot.kernelParams = [
    # Better power management
    "i915.enable_psr=1"
    "i915.enable_fbc=1"
    # Disable GPU power management debugging
    "drm.debug=0"
    # Prefer S3 deep sleep over s2idle
    "mem_sleep_default=deep"
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
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but sometimes works better)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
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


  # Sound configuration with PipeWire (better than PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Input method configuration
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin  # Chinese Simplified Pinyin
      mozc       # Japanese (Romaji)
    ];
  };

  # Prevent automatic suspend on AC power (GNOME power settings)
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };
    };
  }];

  # Touchpad configuration (host-specific overrides)
  services.libinput.touchpad = {
    disableWhileTyping = true;
    accelProfile = "adaptive";
  };

  # TrackPoint configuration (treated as mouse device)
  services.libinput.mouse = {
    accelSpeed = "0.0";         # Higher sensitivity for trackpoint (-1.0 to 1.0)
    accelProfile = "flat";      # No acceleration curve for precise control
    middleEmulation = false;    # ThinkPad trackpoints have real middle buttons
  };

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
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
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

  # Suspend behavior configuration
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";          # Suspend on lid close (all power modes)
      HandleLidSwitchDocked = "ignore";     # Don't suspend when docked
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "suspend";           # Suspend on power button press
      HandleSuspendKey = "suspend";         # Allow manual suspend from GNOME menu
      HandleHibernateKey = "ignore";
      IdleAction = "ignore";                # No automatic idle suspend
      IdleActionSec = "0";
    };
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

  # Enable CUPS for printing
  services.printing.enable = true;

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

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    unzip

    # GPU monitoring
    intel-gpu-tools

    # Laptop utilities
    brightnessctl

    # ThinkPad specific
    lm_sensors  # Temperature monitoring
    smartmontools  # Disk health monitoring (SMART)
  ];


  # Laptop-specific services
  services.acpid.enable = true;
  services.upower.enable = true;

  # Advanced key remapping with keyd
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # Map Caps Lock to Left Control
            capslock = "leftcontrol";
            # Map Right Control to Caps Lock
            rightcontrol = "capslock";
            # Map Left Alt to Super (Windows key)
            leftalt = "leftmeta";
          };
        };
      };
    };
  };

  # Disable internal keyboard when HHKB-Hybrid_1 is connected
  services.disable-keyboard = {
    enable = true;
    externalKeyboardName = "HHKB-Hybrid_1";
  };

  # Apply XKB config to console (TTY) as well
  console.useXkbConfig = true;

  # WireGuard VPN configuration (ThinkPad as client/spoke)
  services.wireguard-custom = {
    enable = true;
    mode = "client";
    privateKeyFile = "/etc/wireguard/thinkpad_private.key";
    clientConfig = {
      address = "10.2.2.30/24";
      serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
      serverEndpoint = "91.98.84.215:51820";
      allowedIPs = [ "10.2.2.0/24" ];
    };
  };

  # Login display with SMART disk health status
  services.login-display = {
    enable = true;
    showSystemInfo = true;
    showSmartStatus = true;
    smartDrives = {
      "/dev/nvme0n1" = "System_SSD";
    };
    showDiskUsage = true;
  };

}
