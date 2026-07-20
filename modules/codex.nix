# Home-manager module that configures the OpenAI Codex CLI.
# It sets program options and permission rules, defines the global context, and wires notification hooks that push to an ntfy topic when a session finishes or needs attention.
# A host opts in by importing this module.

{ config, lib, pkgs, inputs, ... }:

let
  # Pull the codex package from a separate newer nixpkgs input to get releases ahead of the pinned channel.
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  ntfyUrl = "ntfy.sh/yanlincs-homelab";
  notifyThresholdSeconds = 15;
  notifyDir = ''"''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/codex-notify"'';

  # notifyStart records a start time for each session when a prompt is submitted.
  # notifyStop pushes to the ntfy topic when a run finishes or waits for approval, and only when the run lasted at least notifyThresholdSeconds, so quick turns stay silent.
  notifyStart = pkgs.writeShellScript "codex-notify-start" ''
    input=$(cat)
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    dir=${notifyDir}
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    ${pkgs.coreutils}/bin/date +%s > "$dir/$sid.start"
    exit 0
  '';

  notifyStop = pkgs.writeShellScript "codex-notify-stop" ''
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
    event=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.hook_event_name // ""')
    host=$(${pkgs.coreutils}/bin/uname -n | ${pkgs.coreutils}/bin/cut -d. -f1)

    # Name the action after the hook that fired, "Notified" for a PermissionRequest and "Stopped" otherwise.
    if [ "$event" = "PermissionRequest" ]; then
      verb="Notified"
    else
      verb="Stopped"
    fi

    # Report the tmux session and window when the run is inside tmux, and fall back to the working directory otherwise.
    # A screen emoji marks a tmux session and a folder emoji marks a working directory.
    if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && where=$(${pkgs.tmux}/bin/tmux display-message -p -t "$TMUX_PANE" '#S/#W' 2>/dev/null) && [ -n "$where" ]; then
      body="$verb 🖥️ $where"
    else
      body="$verb 📁 $cwd"
    fi

    ${pkgs.curl}/bin/curl -s \
      -H "Title: codex@$host" \
      -d "$body" \
      "https://${ntfyUrl}" >/dev/null 2>&1 || true
    exit 0
  '';

  # Codex settings for ~/.codex/config.toml. features.hooks must be true or Codex ignores hooks.json.
  codexSettings = {
    model_reasoning_effort = "high";
    approval_policy = "on-request";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write = {
      network_access = true;
      writable_roots = [ "${config.home.homeDirectory}/Documents" ];
    };
    web_search = "live";
    tools.view_image = true;
    features.hooks = true;
    tui = {
      animations = false;
      show_tooltips = false;
      theme = "ansi";
    };
  };
  codexConfig = (pkgs.formats.toml { }).generate "codex-config.toml" codexSettings;
in
{
  config = {
    programs.codex = {
      enable = true;
      package = bleed.codex;

      context = ''
        Follow the conventions in this context over any different convention in the files you are working on, unless the user explicitly prompts otherwise.
        These conventions are the preferred defaults and hold across all work, even when a file already follows a different one.
        Conventions from a workdir's CLAUDE.md or a user prompt layer on top of these and usually add to them without conflict.

        ## Environment

        - System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        - If a workdir has a Nix flake development runtime defined in `./runtime/flake.nix`, run commands and scripts that depend on it through `nix develop ./runtime`. Do not directly invoking the binaries the runtime generates, for example `.venv/bin/python`
        - If a workdir has a `Makefile`, use `make` to compile and extend the `Makefile` when needed, instead of running generic compile commands
        - When a CLI tool is needed, first check whether it exists in the host environment. If it does not, run it temporarily through `nix-shell`, for example `nix-shell -p <package> --run '<command>'`
        - The user's personal Obsidian vault is at `~/Documents/app-state/obsidian`. It tracks his projects, their programs, his work log, and drafts, and is the authoritative source for facts about him. Whenever working with the vault, always read its `CLAUDE.md` first for the vault's layout and conventions. A wikilink like `[[Name]]` in a user prompt typically refers to a note in the Obsidian vault

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

      # UserPromptSubmit marks the turn start, Stop marks the turn end, and PermissionRequest fires when Codex pauses to ask for approval.
      hooks = {
        UserPromptSubmit = [
          { hooks = [ { type = "command"; command = "${notifyStart}"; timeout = 5; } ]; }
        ];
        Stop = [
          { hooks = [ { type = "command"; command = "${notifyStop}"; timeout = 15; } ]; }
        ];
        PermissionRequest = [
          { matcher = ""; hooks = [ { type = "command"; command = "${notifyStop}"; timeout = 15; } ]; }
        ];
      };

      # Command permissions as execpolicy rules in ~/.codex/rules/baseline.rules, paired with approval_policy.
      rules = {
        baseline = ''
          prefix_rule(
            pattern = ["git", ["status", "log", "diff", "show"]],
            decision = "allow",
            justification = "Inspecting git state is safe",
          )
          prefix_rule(
            pattern = [["ls", "cat", "head", "tail", "find", "grep", "wc", "file", "which", "pwd"]],
            decision = "allow",
            justification = "These commands only inspect the system and are safe",
          )
          prefix_rule(
            pattern = [["su", "dd", "mkfs", "fdisk"]],
            decision = "forbidden",
            justification = "Privilege escalation and raw disk tools are not permitted",
          )
        '';
      };
    };

    # Codex records per-directory trust into config.toml at runtime and has no global trust setting, so it needs a writable file rather than a read-only store symlink.
    # The copy is reinstalled on each switch, keeping nix authoritative for settings while Codex owns the trust entries it writes between switches.
    home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$HOME/.codex/config.toml"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm0644 ${codexConfig} "$HOME/.codex/config.toml"
    '';

  };
}
