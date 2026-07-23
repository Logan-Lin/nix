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

  # Claude fires a Notification when it waits for input or permission, so treat that event as needing attention.
  inherit (import ./hook.nix { inherit pkgs; agent = "claude"; attentionEvent = "Notification"; }) notifyStart notifyStop;
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
        permissions = {
          allow = [
            "WebSearch"
            "WebFetch"
            "Read"
            "Glob"
            "Grep"

            "Bash(git status:*)"
            "Bash(git log:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"

            "Bash(ls:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(wc:*)"
            "Bash(file:*)"
            "Bash(which:*)"
            "Bash(pwd)"
          ];

          deny = [
            "Bash(su:*)"
            "Bash(dd:*)"
            "Bash(mkfs:*)"
            "Bash(fdisk:*)"
          ];

        };

        hooks = {
          UserPromptSubmit = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${notifyStart}";
                  timeout = 5;
                }
              ];
            }
          ];
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
          # Claude fires a Notification when it waits for input or permission, so reuse notifyStop to push to the ntfy topic and reset the timer.
          Notification = [
            {
              matcher = "";
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
          Express ideas clearly and concisely, and keep the writing focused and coherent without unnecessary framing, transitions, or repetition.
        '';
      };

      commands = {
        proofread = ''
          ---
          description: Proofread text for grammar and spelling issues
          allowed-tools: Read, Edit
          argument-hint: <file>
          ---

          ## Task

          Read the file provided in $ARGUMENTS and proofread it for:
          - Grammar errors
          - Spelling mistakes
          - Punctuation issues
          - Awkward phrasing

          Fix all issues directly in the file using the Edit tool. After editing, provide a brief summary of the changes made. Do not alter meaning, tone, or style. Only correct errors.
        '';

        polish = ''
          ---
          description: Aggressive proofread that fixes errors and enforces writing style rules
          allowed-tools: Read, Edit, Workflow
          argument-hint: <file>
          ---

          ## Task

          Read the file provided in $ARGUMENTS, then proofread and edit it for both basic errors and writing style.

          Fix the following basic errors:
          - Grammar errors
          - Spelling mistakes
          - Punctuation issues
          - Awkward phrasing

          And enforce the following writing style rules:
          - Use plain and direct phrasing. Replace needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions with plain alternatives. For example, "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of"
          - Expand or merge a short, abstract sentence that asserts a point or opens a paragraph and leans on the next sentence to make sense. Give the sentence the specifics it needs to stand on its own, or merge it with the sentence that supplies them. When a sentence marks a transition, state how it connects to what came before and after, instead of only announcing that something changes. For example, "the rewrite cut the average response time in half" instead of "the rewrite changes everything"
          - Replace the "not A but B" phrasing, which rejects an alternative before stating the point, plus its variants such as "not A, but rather B", "it is not A, it is B", "B, not A", and "not only A but also B", with a direct statement of the point. For example, "the bottleneck is the data" instead of "the bottleneck is not the method but the data"
          - Replace hyphenated compound words, whether they join two words or more, with plain phrasing, for example "a value smaller than the limit" instead of "a smaller-than-the-limit value". Leave a hyphenated compound unchanged only when no plain phrasing can replace it, such as "state-of-the-art", "mother-in-law", and "x-ray"
          - Do not use em dashes or en dashes to connect sentences. Split into separate sentences or rephrase
          - Do not use semicolons, colons, or parentheses to join or compress sentences. Rewrite as flowing prose with separate sentences
          - When referring to the same thing, use the exact same term throughout. Remove unnecessary terms and concepts. The only exception is that shorter references can be used when the full term has been established and the short form is obvious from context

          For a longer file, prefer a workflow over a single pass. Use several reviewers to find edits, have separate judges check each edit to avoid needless changes, then apply only the ones that pass. 

          Fix all issues directly in the file using the Edit tool. After editing, provide a brief summary of the changes made. Do not alter the underlying meaning. Only adjust wording, phrasing, and formatting to meet the rules.
        '';

        fact-check = ''
          ---
          description: Check the target file for factual errors against reputable sources
          allowed-tools: Read, Edit, WebSearch, WebFetch, Workflow
          argument-hint: <file>
          ---

          ## Task

          Read the file provided in $ARGUMENTS and check it for factual errors:
          - Identify concrete factual claims (names, dates, numbers, attributions, definitions, events, technical specifications, etc.)
          - Verify each claim against reputable and relatively recent sources via WebSearch and WebFetch. Prefer primary sources, official documentation, peer-reviewed publications, and well-established outlets. Avoid relying on a single low-quality source
          - Skip opinions, subjective statements, and unverifiable claims

          For a file with many claims, prefer a workflow over a single pass. Have several agents check the claims at the same time, confirm each suspected error against more than one source, then fix only the ones that are truly wrong.

          For any confirmed factual error, fix it directly in the file using the Edit tool with the minimal change needed to make the statement correct. Do not rewrite surrounding text, alter style, or restructure prose.

          After editing, provide a brief summary listing each correction made, with the source used to verify it. If no errors were found, state that explicitly.
        '';

        commit = ''
          ---
          description: Commit the current change as a single subject line
          allowed-tools: Read, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
          argument-hint: [optional summary hint]
          ---

          ## Task

          Commit the current working tree change as one commit.

          1. Stage and review the change.
          2. Write the message as a single lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` is a concise description of the change
          3. Commit with the message. Write only the subject line, with no body and no attribution trailer.

          When $ARGUMENTS is given, use it as guidance for the summary. Stay on the current branch and do not push.
        '';
      };
    };
  };
}
