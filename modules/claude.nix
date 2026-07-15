{ pkgs, inputs, ... }:

let
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  ntfyUrl = "ntfy.sh/yanlincs-homelab";
  notifyThresholdSeconds = 15;
  notifyDir = ''"''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/claude-notify"'';

  notifyStart = pkgs.writeShellScript "claude-notify-start" ''
    input=$(cat)
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    dir=${notifyDir}
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    ${pkgs.coreutils}/bin/date +%s > "$dir/$sid.start"
    exit 0
  '';

  notifyStop = pkgs.writeShellScript "claude-notify-stop" ''
    input=$(cat)
    dir=${notifyDir}
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    startfile="$dir/$sid.start"
    [ -f "$startfile" ] || exit 0
    start=$(${pkgs.coreutils}/bin/cat "$startfile" 2>/dev/null || echo 0)
    ${pkgs.coreutils}/bin/rm -f "$startfile"
    now=$(${pkgs.coreutils}/bin/date +%s)
    elapsed=$(( now - start ))
    [ "$elapsed" -ge ${toString notifyThresholdSeconds} ] || exit 0

    cwd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.cwd // ""')
    proj=$(${pkgs.coreutils}/bin/basename "$cwd" 2>/dev/null || echo session)
    host=$(${pkgs.coreutils}/bin/uname -n | ${pkgs.coreutils}/bin/cut -d. -f1)

    body=$(${pkgs.coreutils}/bin/printf 'Stopped in %s' "$cwd")

    ${pkgs.curl}/bin/curl -s \
      -H "Title: claude on $host: $proj" \
      -d "$body" \
      "https://${ntfyUrl}" >/dev/null 2>&1 || true
    exit 0
  '';
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
        ultracode = true;
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

      context = ''
        Follow the conventions in this context over any different convention in the files you are working on, unless the user explicitly prompts otherwise.
        These conventions are the preferred defaults and hold across all work, even when a file already follows a different one.
        Conventions from a workdir's CLAUDE.md or a user prompt layer on top of these and usually add to them without conflict.

        ## Environment

        - System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        - If a workdir has a Nix flake development runtime defined in `./runtime/flake.nix`, run commands and scripts that depend on it through `nix develop ./runtime`. Do not directly invoking the binaries the runtime generates, for example `.venv/bin/python`
        - If a workdir has a `Makefile`, use `make` to compile and extend the `Makefile` when needed, instead of running generic compile commands
        - When a CLI tool is needed, first check whether it exists in the host environment. If it does not, run it temporarily through `nix-shell`, for example `nix-shell -p <package> --run '<command>'`
        - The user's personal Obsidian vault is at `~/Documents/app-state/obsidian`. It tracks his projects, their programs, his work log, and drafts, and is the authoritative source for facts about him. Read its `CLAUDE.md` for the layout and where specific information is. A wikilink like `[[Name]]` in a user prompt typically refers to a note in the Obsidian vault

        ## Writing Style

        For any natural language text content, such as notes, reports, papers, messages, and code comments, strictly follow the writing rules below.

        - Use plain and direct phrasing. For example, write "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of". Do not use needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions
        - Do not assert a point or open a paragraph with a short, abstract sentence that leans on the next sentence to make sense. Give the sentence the specifics it needs to stand on its own, or merge it with the sentence that supplies them. When a sentence marks a transition, state how it connects to what came before and after, instead of only announcing that something changes. For example, write "the rewrite cut the average response time in half" instead of "the rewrite changes everything"
        - Do not phrase a point as "not A but B", rejecting an alternative before stating the point, which reads indirect. This includes variants like "not A, but rather B", "it is not A, it is B", "B, not A", and "not only A but also B". State the point directly, for example "the bottleneck is the data" instead of "the bottleneck is not the method but the data"
        - Do not use hyphenated compound words, whether they join two words or more. Rephrase them as plain words, for example write "a value smaller than the limit" instead of "a smaller-than-the-limit value". A hyphenated compound word is acceptable only when no plain phrasing can replace it, such as "state-of-the-art", "mother-in-law", and "x-ray"
        - When referring to the same thing, use the exact same term or concept throughout, to avoid confusion. Do not introduce unnecessary terms and concepts. Only exception is that when the same term or concept is referred repeatedly, shorter references can be used when obvious and self-explanatory from context
        - Do not use em dashes or en dashes to connect sentences
        - Do not use punctuation like semicolons, colons, or parentheses to join or compress sentences

        ## Formatting

        - For any natural language text content, do not use formatting like bold, italic, itemized lists, or enumerated lists
        - When writing code, write a code document or comment only when the code does not speak for itself, and keep it at a high level. Do not repeat details already in the code. Focus on the overall purpose and role of the code
        - For text content where linebreaks do not affect rendering, for example Markdown, LaTeX, and code comments, break lines between sentences to make diffs and editing easier
        - For any natural language text content, never break a line in the middle of a sentence, including code documents and comments
        - When drafting a git commit message, write a single lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` is a concise description of the change. Do not include a body
      '';

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
