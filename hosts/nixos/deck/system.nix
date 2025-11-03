{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../system-default.nix  # Common NixOS system configuration
    ../../../modules/desktop.nix
    ../../../modules/wireguard.nix
    ../../../modules/login-display.nix
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

  # Input method configuration
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin  # Chinese Simplified Pinyin
      mozc       # Japanese (Romaji)
    ];
  };

  # GNOME settings (prevent suspend, enable virtual keyboard)
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };
      "org/gnome/desktop/a11y/applications" = {
        screen-keyboard-enabled = true;
      };
      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat";
      };
    };
  }];

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

  # Jovian Steam Deck configuration
  jovian = {
    hardware.has.amd.gpu = true;  # Enables backlight control and early modesetting

    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "gnome";
      user = "yanlin";
    };
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
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

    smartmontools  # Disk health monitoring (SMART)
  ];

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
