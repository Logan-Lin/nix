# Integrations that connect the agent CLIs to other programs and services.
{
  lib,
  pkgs,
}:
let
  # TODO: Remove the patch once the nixpkgs version catches up.
  firefox-devtools-mcp = pkgs.firefox-devtools-mcp.overrideAttrs (finalAttrs: old: {
    version = "0.10.6";
    src = pkgs.fetchFromGitHub {
      owner = "mozilla";
      repo = "firefox-devtools-mcp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-Z3cxGgJia1QrYewLGjmVR1f6daZNI+K4qGFg3vYIN6M=";
    };
    npmDeps = pkgs.fetchNpmDeps {
      name = "${old.pname}-${finalAttrs.version}-npm-deps";
      inherit (finalAttrs) src;
      hash = "sha256-x6MnmMZPDQtBC2p7oL5p9yWlI9CkvvzoPB323OMCzv0=";
    };
    postPatch = "";
  });

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
in
{
  notion = {
    type = "http";
    url = "https://mcp.notion.com/mcp";
  };

  # NOTE: This server only bridges to the Thunderbird MCP add-on installed by hand.
  # Get the add-on from https://github.com/TKasperczyk/thunderbird-mcp
  thunderbird = {
    command = lib.getExe pkgs.thunderbird-mcp;
  };

  # Mozilla's server opens a separate Camoufox instance on a temporary profile, so multiple agents can each run their own.
  firefox = {
    command =
      if pkgs.stdenv.hostPlatform.isLinux then
        # Run the browser headless when the agent runs outside a graphical session, such as on a server or over SSH.
        toString (pkgs.writeShellScript "firefox-devtools-mcp" ''
          if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
            set -- "$@" --headless
          fi
          exec ${lib.getExe firefox-devtools-mcp} "$@"
        '')
      else
        lib.getExe firefox-devtools-mcp;
    args = [ "--tool-preset" "developer" "--firefoxPath" camoufox.executable ];
  };
}
