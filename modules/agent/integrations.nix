# Integrations that connect the agent CLIs to other programs and services.
{
  config,
  lib,
  pkgs,
}:
let
  # Camoufox, a browser that hides automation from web pages, packaged from its binary releases.
  camoufox =
    let
      releases = {
        aarch64-darwin = {
          name = "mac.arm64";
          hash = "sha256-kDj4bWZsl4C2//GZ1Ihze4WWwB8k4+UXhFoOz7DPit0=";
        };
        x86_64-linux = {
          name = "lin.x86_64";
          hash = "sha256-Py6x0EUfpY5F5D5V9eYYFWUGl5GuYMBXTwzrHwE0HDM=";
        };
      };
      release = releases.${pkgs.stdenv.hostPlatform.system};
      inherit (pkgs.stdenv.hostPlatform) isLinux;
      paths = if isLinux then {
        executable = "lib/camoufox/camoufox";
        applicationIni = "lib/camoufox/application.ini";
      } else {
        executable = "Applications/Camoufox.app/Contents/MacOS/camoufox";
        applicationIni = "Applications/Camoufox.app/Contents/Resources/application.ini";
      };
    in
    pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "camoufox";
      version = "158.0.1-beta.41";

      src = pkgs.fetchurl {
        url = "https://github.com/daijro/camoufox/releases/download/v${finalAttrs.version}/camoufox-${finalAttrs.version}-${release.name}.zip";
        inherit (release) hash;
      };

      # The Linux archive has no top-level directory, so unpack into one.
      unpackCmd = "unzip -q $curSrc -d source";

      # Patch the Linux build the way nixpkgs patches firefox-bin.
      nativeBuildInputs = [ pkgs.unzip ]
        ++ lib.optionals isLinux (with pkgs; [ autoPatchelfHook patchelfUnstable ]);
      buildInputs = lib.optionals isLinux (with pkgs; [ gtk3 adwaita-icon-theme alsa-lib dbus-glib libxtst ]);
      runtimeDependencies = lib.optionals isLinux (with pkgs; [ curl pciutils libva.out ]);
      appendRunpaths = lib.optionals isLinux [ "${pkgs.pipewire}/lib" ];
      patchelfFlags = [ "--no-clobber-old-sections" ];

      # Leave the macOS binaries untouched so their code signatures stay valid.
      dontFixup = !isLinux;

      installPhase =
        if isLinux then ''
          runHook preInstall
          mkdir -p $out/lib
          cp -r . $out/lib/camoufox
          runHook postInstall
        '' else ''
          runHook preInstall
          mkdir -p $out/Applications
          mv Camoufox.app $out/Applications/
          runHook postInstall
        '';

      # geckodriver only accepts Firefox-style version numbers, so drop the release suffix.
      postInstall = ''
        sed -i 's/^Version=\([^-]*\)-.*/Version=\1/' $out/${paths.applicationIni}
      '';

      # geckodriver reads the version from files beside the real executable, so launch it directly.
      passthru.executable = "${finalAttrs.finalPackage}/${paths.executable}";

      meta = {
        description = "Browser that hides automation from web pages";
        homepage = "https://github.com/daijro/camoufox";
        license = lib.licenses.mpl20;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        platforms = builtins.attrNames releases;
      };
    });

  librewolf =
    let
      cfg = config.programs.librewolf;
    in
    if !cfg.enable then null
    else if cfg.finalPackage != null then lib.getExe cfg.finalPackage
    else if pkgs.stdenv.hostPlatform.isDarwin then "/Applications/LibreWolf.app/Contents/MacOS/librewolf"
    else null;

  browserServer = executable: extraArgs: {
    command = lib.getExe pkgs.firefox-devtools-mcp;
    args = [ "--tool-preset" "developer" "--firefoxPath" executable ] ++ extraArgs;
  };

  integrations = {
    notion = {
      description = "Connects to the user's Notion workspace. Used for publishing notes that need collaborative viewing and editing.";
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };

    # NOTE: This server only bridges to the Thunderbird MCP add-on installed by hand.
    # Get the add-on from https://github.com/TKasperczyk/thunderbird-mcp
    thunderbird = {
      description = "Controls the Thunderbird desktop client through its MCP add-on. Used to access the user's email accounts.";
      command = lib.getExe pkgs.thunderbird-mcp;
    };

    camoufox = {
      description = "Controls a headless Camoufox browser with a fresh temporary profile in each session. Used for automated fetching of web content.";
    } // browserServer camoufox.executable [ "--headless" ];
  }
  // lib.optionalAttrs (librewolf != null) {
    librewolf = {
      description = "Controls a LibreWolf GUI browser with a fresh temporary profile in each session. Used only when the user asks for it.";
    } // browserServer librewolf [ ];
  };
in
{
  mcpServers = lib.mapAttrs (_: integration: removeAttrs integration [ "description" ]) integrations;

  context = ''

    ## Integrations

    MCP-based integrations connecting to other programs and services. Note that some of them might be unavailable when the program they connect to is not running.

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: integration: "- `${name}`: ${integration.description}") integrations)}
  '';
}
