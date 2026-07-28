# Home-manager module that configures the Claude Code CLI.
# It sets program options and permissions, defines the global context and custom slash commands, and wires notification hooks that push to an ntfy topic when a session finishes or needs attention.
# A host opts in by importing this module.

{ pkgs, inputs, ... }:

let
  # Pull the claude-code package from a separate newer nixpkgs input to get releases ahead of the pinned channel.
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Selected Notification types mean Claude needs input or permission, so treat that event as needing attention.
  inherit (import ./hook.nix { inherit pkgs; agent = "claude"; attentionEvent = "Notification"; }) notifyStop;
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
        skipAutoPermissionPrompt = true;
        effortLevel = "xhigh";
        ultracode = false;
        enableWorkflows = true;
        terminalProgressBarEnabled = false;
        theme = "dark-ansi";
        attribution = {
          commit = "";
        };

        hooks = {
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${notifyStop}";
                  timeout = 15;
                }
              ];
            }
          ];
          # Match only notifications that mean Claude is blocked on user input.
          Notification = [
            {
              matcher = "permission_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input|worker_permission_prompt";
              hooks = [
                {
                  type = "command";
                  command = "${notifyStop}";
                  timeout = 15;
                }
              ];
            }
          ];
        };
      };

      context = import ./context.nix {
        memoryFile = "CLAUDE.md";
        additionalContext = ''

          ## Additional Instructions

          When writing any natural language text content, use a direct and straightforward style.
          Express ideas clearly and concisely, using only the framing, transitions, and repetition needed for coherence.
          Keep the writing centered on its core ideas, and add supporting context only when it improves understanding, accuracy, or completeness.
        '';
      };

      commands = import ./commands.nix;
    };
  };
}
