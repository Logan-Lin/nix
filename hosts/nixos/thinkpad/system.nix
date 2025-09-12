{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
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
      powerOnBoot = false; # Save battery
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

  # Time zone and localization
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  # Sound configuration with PipeWire (better than PulseAudio)
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # KDE Plasma Desktop Environment
  services.xserver = {
    enable = true;
    
    # Video drivers
    videoDrivers = [ "modesetting" "nvidia" ];
    
    # Display manager
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    
    # Desktop environment
    desktopManager.plasma6.enable = true;
    
    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };
    
    # Touchpad configuration
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
        accelProfile = "adaptive";
      };
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
      
      # Disable Bluetooth on battery to save power
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
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

  # SSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # User account
  users.users.yanlin = {
    isNormalUser = true;
    description = "yanlin";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$8NUV0JK33hs3XBYe$osnYKzENDLYHQEpj8Z5F6ECpLdc8Y3RZcVGxQ0bc/6DepTwugAkfX8h6ItI01dJyk8RstiGsWVVCKGwXaL.sN.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    git
    wget
    curl
    htop
    btop
    neofetch
    tree
    unzip
    
    # Development tools
    tmux
    zsh
    home-manager
    
    # KDE/Plasma utilities
    kate
    konsole
    spectacle
    filelight
    ark
    
    # System utilities
    pciutils
    usbutils
    lshw
    inxi
    
    # GPU monitoring
    nvtopPackages.nvidia
    intel-gpu-tools
    
    # Laptop utilities
    brightnessctl
    acpi
    powertop
    s-tui  # Stress test and monitoring
    
    # ThinkPad specific
    lm_sensors  # Temperature monitoring
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages (needed for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # Laptop-specific services
  services.acpid.enable = true;
  services.upower.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "24.05";
}