{ config, pkgs, lib, ... }:

let
  # Helper function to patch desktop entries for NVIDIA offload
  patchDesktop = pkg: appName: from: to: lib.hiPrio (
    pkgs.runCommand "patched-desktop-entry-for-${appName}" {} ''
      ${pkgs.coreutils}/bin/mkdir -p $out/share/applications
      ${pkgs.gnused}/bin/sed 's#${from}#${to}#g' < ${pkg}/share/applications/${appName}.desktop > $out/share/applications/${appName}.desktop
    ''
  );

  # Wrapper to automatically run applications with NVIDIA offload
  GPUOffloadApp = pkg: desktopName: patchDesktop pkg desktopName "^Exec=" "Exec=nvidia-offload ";
in

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix  # Host-specific container definitions
    ../system-default.nix  # Common NixOS system configuration
    ../../../modules/wireguard.nix
    ../../../modules/podman.nix
    ../../../modules/login-display.nix
  ];

  # Bootloader - standard UEFI setup
  boot.loader = {
    systemd-boot.enable = true;
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

  # Enable firmware updates
  services.fwupd.enable = true;
  
  # Hardware support for ThinkPad P14s Gen 2 Intel
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    
    # Graphics configuration
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver  # LIBVA_DRIVER_NAME=iHD
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but sometimes works better)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    
    # NVIDIA configuration (T500)
    nvidia = {
      # Modesetting is required for PRIME
      modesetting.enable = true;
      
      # Power management (experimental but useful for laptops)
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      
      # Use proprietary driver (open source doesn't support T500 well)
      open = false;
      
      # Enable nvidia-settings application
      nvidiaSettings = true;
      
      # Use production driver (more stable than latest)
      package = config.boot.kernelPackages.nvidiaPackages.production;
      
      # PRIME Offload configuration (better battery life)
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true; # Provides nvidia-offload command
        };
        
        # Bus IDs - MUST be verified after installation with:
        # lspci | grep -E 'VGA|3D'
        # These are typical values but may differ
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
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
    jack.enable = true;
  };

  # GNOME Desktop Environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable NVIDIA video drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Steam gaming configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Enable GameMode for performance optimization
  programs.gamemode.enable = true;

  # Keyboard layout
  services.xserver.xkb = {
    layout = "us";
    options = "";
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

  # Exclude unwanted GNOME default packages
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany  # GNOME web browser
    geary     # GNOME email client
    gnome-music
    gnome-photos
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-clocks
    simple-scan
    totem     # video player
    yelp      # help viewer
  ];

  # XDG portal for proper desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # Touchpad configuration
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      disableWhileTyping = true;
      accelProfile = "adaptive";
    };
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
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Intel GPU power management
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 900;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1100;
      
      # ThinkPad battery charge thresholds (preserve battery health)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      # PCIe power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      
      # Keep Bluetooth available on battery
      # DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
    };
  };

  # Suspend behavior configuration
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";          # Suspend on lid close (battery only)
      HandleLidSwitchDocked = "ignore";
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
    nvtopPackages.nvidia
    intel-gpu-tools

    # Laptop utilities
    brightnessctl

    # ThinkPad specific
    lm_sensors  # Temperature monitoring
    smartmontools  # Disk health monitoring (SMART)

    # Gaming utilities
    mangohud  # Performance overlay for games
    gamescope  # SteamOS session compositing window manager
    protonup-qt  # Proton version manager

    # Steam with NVIDIA offload (patched desktop entry)
    (GPUOffloadApp config.programs.steam.package "steam")
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
            # Disable both physical Ctrl keys (make them no-ops)
            leftcontrol = "noop";
            rightcontrol = "noop";
          };
        };
      };
    };
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
