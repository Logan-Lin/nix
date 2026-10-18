# Integrations that connect the agent CLIs to other programs and services.
{
  config,
  lib,
  pkgs,
}:
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
}
// lib.optionalAttrs config.programs.firefox.enable {
  # Mozilla's server opens a separate Firefox window with its own persistent profile under this path.
  firefox = {
    command = lib.getExe pkgs.firefox-devtools-mcp;
    args = [ "--profile-path" "${config.home.homeDirectory}/.firefox-devtools-mcp" ];
  };
}
