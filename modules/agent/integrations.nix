# Integrations that connect the agent CLIs to other programs and services.
{
  config,
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

  # Mozilla's server opens a separate Firefox instance on a temporary profile, so multiple agents can each run their own.
  firefox = {
    command = lib.getExe firefox-devtools-mcp;
    args = [ "--tool-preset" "developer" ]
      # Hosts without a Firefox installation run a bundled one in headless mode.
      ++ lib.optionals (!config.programs.firefox.enable) [
        "--headless"
        "--firefoxPath" (lib.getExe pkgs.firefox)
      ];
  };
}
