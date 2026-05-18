{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.hyprland-system-custom;
in

{
  options.hyprland-system-custom = {
    enableDisplayManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable greetd display manager";
    };
  };

  config = {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    services.greetd = mkIf cfg.enableDisplayManager {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "hyprland;gtk";
    };

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans" "Noto Sans CJK SC" "Noto Sans CJK TC" "Noto Sans CJK JP" "Noto Sans CJK KR" ];
      serif = [ "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" "Noto Serif CJK KR" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" "Noto Sans Mono CJK SC" "Noto Sans Mono CJK TC" "Noto Sans Mono CJK JP" "Noto Sans Mono CJK KR" ];
      emoji = [ "Noto Color Emoji" ];
    };

    programs.dconf.enable = true;
    programs.xfconf.enable = true;

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          qt6Packages.fcitx5-chinese-addons
          fcitx5-mozc
          fcitx5-gtk
        ];
        settings = {
          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "keyboard-us";
            };
            "Groups/0/Items/0" = {
              Name = "keyboard-us";
              Layout = "";
            };
            "Groups/0/Items/1" = {
              Name = "pinyin";
              Layout = "";
            };
            "Groups/0/Items/2" = {
              Name = "mozc";
              Layout = "";
            };
          };
          globalOptions = {
            Hotkey = {
              EnumerateWithTriggerKeys = "True";
            };
            "Hotkey/TriggerKeys" = {
              "0" = "Control+space";
            };
          };
        };
      };
    };

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = mkIf cfg.enableDisplayManager true;

    environment.systemPackages = with pkgs; [
      hypridle
      hyprlock
      hyprpolkitagent
      tuigreet
      waybar
      wofi
      networkmanagerapplet
      pavucontrol
      brightnessctl
      nwg-displays
      swaynotificationcenter
      qt5.qtwayland
      qt6.qtwayland
      iptables
    ];

    services.upower.enable = true;
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = false;
        disableWhileTyping = true;
      };
    };

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

    services.printing = {
      enable = true;
      browsing = true;
      drivers = with pkgs; [
        cups-filters
        gutenprint
        samba
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    programs.system-config-printer.enable = true;
  };
}
