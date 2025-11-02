{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../system-default.nix  # Common NixOS system configuration
    ../../../modules/desktop.nix
    ../../../modules/wireguard.nix
  ];

  # Desktop module configuration (disable GDM for Jovian autoStart mode)
  desktop-custom.enableDisplayManager = false;

  # Bootloader - standard UEFI setup
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Use latest kernel for better hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network configuration
  networking = {
    hostName = "deck";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
    firewall.enable = false;
  };

  # WireGuard VPN configuration
  services.wireguard-custom = {
    enable = true;
    mode = "client";
    clientConfig = {
      address = "10.2.2.40/32";
      serverEndpoint = "91.98.84.215:51820";
      serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
      allowedIPs = [ "10.2.2.0/24" ];  # Only route WireGuard network through VPN
    };
  };

  # Hardware support for Steam Deck (AMD APU)
  hardware = {
    enableRedistributableFirmware = true;

    # Graphics configuration for AMD
    # Note: enable32Bit is set by jovian.steam.enable
    graphics.enable = true;

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

  # Sound configuration with PipeWire (required for Jovian's DSP layer)
  sound.enable = true;                 # Enable ALSA sound card drivers
  services.pulseaudio.enable = false;  # Disable PulseAudio in favor of PipeWire
  security.rtkit.enable = true;        # RealtimeKit for low-latency audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;                # ALSA compatibility
    alsa.support32Bit = true;          # 32-bit game support
    pulse.enable = true;               # PulseAudio compatibility for apps
  };

  # Jovian Steam Deck configuration
  jovian = {
    hardware.has.amd.gpu = true;  # Enables backlight control and early modesetting

    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "gnome";
      user = "yanlin";
    };
    decky-loader.enable = true;
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
      enableSoundSupport = true;  # Steam Deck-optimized PipeWire with DSP
      enableVendorDrivers = true;  # Uses Valve's driver branches instead of upstream
    };
    steamos = {
      useSteamOSConfig = true;  # Enable SteamOS optimizations (zram, OOM, sysctl, etc.)
      enableBluetoothConfig = true;  # SteamOS bluetooth defaults
      enableAutoMountUdevRules = true;  # Auto-mount SD cards
    };
  };

  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "no";
    };
  };

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    hashedPassword = "$6$kSyaRzAtj8VPcNeX$NsEP6zQAfp6O8YWcolfPRKnhIcJlKu5luZgWqozJAHtbE/gv90KoOOKU7Dt.FnbPB0Ej26jXoBH4X.7y/OLGB1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzmzq6xXp7KkUfPsFo/4O7AYVCJ1U+GrbD0fB10izMF yanlin@thinkpad"
    ];
  };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    unzip
  ];

}
