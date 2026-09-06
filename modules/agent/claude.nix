# Home-manager module that configures the Claude Code CLI.
# It sets program options and permissions, and defines the global context and custom slash commands.
# A host opts in by importing this module.

{ pkgs, inputs, ... }:

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
        spinnerTipsEnabled = false;
        todoEnabled = true;
        autoCompactEnabled = true;
        autoMemoryEnabled = false;
        alwaysThinkingEnabled = true;
        feedbackSurveyRate = 0;
        env = {
          CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
        };
        prefersReducedMotion = true;
        promptSuggestionEnabled = false;
        awaySummaryEnabled = false;
        skipAutoPermissionPrompt = true;
        effortLevel = "xhigh";
        ultracode = false;
        enableWorkflows = true;
        workflowSizeGuideline = "large";
        terminalProgressBarEnabled = false;
        theme = "dark-ansi";
        attribution = {
          commit = "";
        };

        remoteControlAtStartup = true;
        inputNeededNotifEnabled = true;
        agentPushNotifEnabled = true;
      };

      context = import ./context.nix {
        memoryFile = "CLAUDE.md";
        additionalContext = ''

          ## Workflow Orchestration 

          When launching a workflow, choosing optimally between the `opus` and `fable` models for the agents.
        '';
      };

      commands = import ./commands.nix;
    };
  };
}
