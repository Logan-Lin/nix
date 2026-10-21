{ config, lib, pkgs, inputs, ... }:

let
  # Pull the claude-code package from a separate newer nixpkgs input to get releases ahead of the pinned channel.
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  config = {
    programs.claude-code = {
      enable = true;
      package = bleed.claude-code;

      settings = {
        autoMemoryEnabled = false;
        feedbackSurveyRate = 0;
        env = {
          CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          CLAUDE_CODE_EFFORT_LEVEL = "xhigh";
        };
        prefersReducedMotion = true;
        enableWorkflows = true;
        theme = "dark-ansi";

        remoteControlAtStartup = true;
        inputNeededNotifEnabled = true;
        agentPushNotifEnabled = true;
      };

      context = import ./context.nix { memoryFile = "CLAUDE.md"; };

      commands = import ./commands.nix;

      mcpServers = import ./integrations.nix { inherit config lib pkgs; };
    };
  };
}
