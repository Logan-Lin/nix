{ config, lib, pkgs, ... }:

let
  setFileAssociationsScript = pkgs.writeText "set-file-associations.swift" ''
    import AppKit
    import UniformTypeIdentifiers

    let associations: [(bundleId: String, extensions: [String])] = [
      ("com.apple.TextEdit", [
        "txt", "md", "markdown", "nix", "sh", "bash", "zsh", "fish",
        "py", "js", "ts", "jsx", "tsx", "json", "yaml", "yml", "toml",
        "xml", "css", "log", "csv", "conf", "config", "ini", "env",
        "c", "cpp", "h", "hpp", "rs", "go", "java", "rb", "php",
        "lua", "vim", "tex", "bib"
      ]),
      ("com.apple.Preview", [
        "pdf", "png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif",
        "webp", "heic", "heif", "ico"
      ]),
      ("org.inkscape.Inkscape", ["svg"]),
      ("com.jgraph.drawio.desktop", ["drawio"]),
      ("com.colliderli.iina", [
        "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v",
        "mpg", "mpeg", "mp3", "m4a", "flac", "wav", "aac", "ogg", "opus"
      ])
    ]

    let ws = NSWorkspace.shared

    for (bundleId, extensions) in associations {
      guard let appURL = ws.urlForApplication(withBundleIdentifier: bundleId) else {
        fputs("Warning: app not found: \(bundleId), skipping\n", stderr)
        continue
      }
      for ext in extensions {
        guard let utType = UTType(filenameExtension: ext) else { continue }
        ws.setDefaultApplication(at: appURL, toOpen: utType)
      }
    }
  '';
in
{
  imports = [
    ../home-default.nix
    ../../modules/ghostty.nix
    ../../modules/claude.nix
    ../../modules/firefox.nix
    ../../modules/syncthing.nix
    ../../modules/media-tool.nix
  ];

  syncthing-custom.folders = {
    Documents.enable = true;
  };

  programs.firefox-custom = {
    enable = true;
    package = null;
  };

  programs.ghostty-custom = {
    enable = true;
    package = null;
  };

  home.homeDirectory = "/Users/yanlin";

  programs.zsh.shellAliases = {
    oss = "sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)";
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie

    choose-gui
  ];

  launchd.agents.maccy = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Maccy.app/Contents/MacOS/Maccy" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.linearmouse = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  home.activation.setFileAssociations = config.lib.dag.entryAfter ["writeBoundary"] ''
    run /usr/bin/swift ${setFileAssociationsScript}
  '';

  home.file.".config/linearmouse/linearmouse.json".text = builtins.toJSON {
    schemes = [{
      "if".device.category = "mouse";
      scrolling.distance = "128px";
      scrolling.reverse = {
        vertical = true;
        horizontal = false;
      };
      pointer = {
        acceleration = 0;
        speed = 0.65;
      };
      buttons.mappings = [
        {
          button = 2;
          action = "smartZoom";
        }
      ];
    }];
  };

  home.file.".aerospace.toml".source = (pkgs.formats.toml { }).generate "aerospace.toml" {
    config-version = 2;

    workspace-to-monitor-force-assignment."10" = "secondary";

    on-window-detected = [
      { "if" = "true"; run = [ "layout floating" ]; }
    ];

    mode.main.binding = {
      alt-enter = "layout floating tiling";
      alt-f = "fullscreen";
      alt-q = "close";

      alt-h = "focus left";
      alt-j = "focus down";
      alt-k = "focus up";
      alt-l = "focus right";

      alt-shift-h = "move left";
      alt-shift-j = "move down";
      alt-shift-k = "move up";
      alt-shift-l = "move right";

      alt-minus = "resize smart -50";
      alt-equal = "resize smart +50";

      alt-1 = "workspace 1";
      alt-2 = "workspace 2";
      alt-3 = "workspace 3";
      alt-4 = "workspace 4";
      alt-5 = "workspace 5";
      alt-6 = "workspace 6";
      alt-7 = "workspace 7";
      alt-8 = "workspace 8";
      alt-9 = "workspace 9";
      alt-0 = "workspace 10";

      alt-comma = "focus-monitor prev";
      alt-period = "focus-monitor next";

      alt-shift-comma = "move-node-to-monitor prev";
      alt-shift-period = "move-node-to-monitor next";

      alt-shift-1 = [ "move-node-to-workspace 1" "workspace 1" ];
      alt-shift-2 = [ "move-node-to-workspace 2" "workspace 2" ];
      alt-shift-3 = [ "move-node-to-workspace 3" "workspace 3" ];
      alt-shift-4 = [ "move-node-to-workspace 4" "workspace 4" ];
      alt-shift-5 = [ "move-node-to-workspace 5" "workspace 5" ];
      alt-shift-6 = [ "move-node-to-workspace 6" "workspace 6" ];
      alt-shift-7 = [ "move-node-to-workspace 7" "workspace 7" ];
      alt-shift-8 = [ "move-node-to-workspace 8" "workspace 8" ];
      alt-shift-9 = [ "move-node-to-workspace 9" "workspace 9" ];
      alt-shift-0 = [ "move-node-to-workspace 10" "workspace 10" ];

      alt-tab = "exec-and-forget /opt/homebrew/bin/aerospace list-windows --all --format '%{window-id} | %{app-name}: %{window-title}' | ${pkgs.choose-gui}/bin/choose | ${pkgs.coreutils}/bin/cut -d'|' -f1 | ${pkgs.findutils}/bin/xargs /opt/homebrew/bin/aerospace focus --window-id";
    };
  };

}
