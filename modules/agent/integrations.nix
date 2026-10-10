# Integrations that connect the agent CLIs to other programs, each added only on hosts that have the program.
{
  config,
  lib,
  pkgs,
}:
lib.optionalAttrs config.programs.firefox.enable {
  # Mozilla's server opens a separate Firefox window with its own persistent profile under this path.
  firefox = {
    command = lib.getExe pkgs.firefox-devtools-mcp;
    args = [ "--profile-path" "${config.home.homeDirectory}/.firefox-devtools-mcp" ];
  };
}
