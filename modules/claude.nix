{ pkgs, inputs, ... }:

let
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  config = {
    home.packages = [
      pkgs.poppler-utils
      pkgs.pandoc
      pkgs.yq-go
    ];

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
        permissions = {
          allow = [
            "WebSearch"
            "WebFetch"
            "Read"
            "Glob"
            "Grep"
            "Write(~/.claude/**)"
            "Edit(~/.claude/**)"

            "Bash(git status)"
            "Bash(git status:*)"
            "Bash(git log:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(git remote:*)"
            "Bash(git ls-files:*)"
            "Bash(gh api:*)"

            "Bash(nix-shell:*)"
            "Bash(nix develop:*)"
            "Bash(nix build:*)"
            "Bash(nix run:*)"
            "Bash(nix-env -q:*)"
            "Bash(nix search:*)"
            "Bash(nix eval:*)"
            "Bash(nix flake show:*)"
            "Bash(nix flake metadata:*)"
            "Bash(nix flake check:*)"
            "Bash(nix derivation show:*)"
            "Bash(nix why-depends:*)"
            "Bash(nix path-info:*)"
            "Bash(nix log:*)"
            "Bash(nix registry:*)"

            "Bash(cd:*)"
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(file:*)"
            "Bash(du:*)"
            "Bash(tree:*)"
            "Bash(pdftotext:*)"
            "Bash(curl:*)"
            "Bash(yq:*)"

            "Bash(which:*)"
            "Bash(whereis:*)"
            "Bash(whoami)"
            "Bash(pwd)"
            "Bash(uname:*)"
            "Bash(date)"
            "Bash(echo:*)"
          ];

          deny = [
            "Bash(su:*)"
            "Bash(dd:*)"
            "Bash(mkfs:*)"
            "Bash(fdisk:*)"
          ];

        };
      };

      context = ''
        ## Environment
        1. System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        2. Projects may use Nix flake development runtime, activate through `nix develop ./runtime` or alias `ndr`. Check whether the workdir have such runtime before running commands
        3. Projects may have custom `make` processes. Check whether the workdir have a `Makefile` before running generic compile commands
        4. A personal Obsidian vault at `~/Documents/app-state/obsidian` is the user's project-management vault. It tracks his projects, their programs, his work log, and drafts, and is the authoritative source for facts about him. Read its `CLAUDE.md` for the layout and where specific information is

        ## Writing Style
        1. Do not write code documents or comments unless explicitly instructed
        2. For any natural language text content, such as notes, reports, papers, messages, and code comments, follow the detailed rules below
          - Use plain and direct phrasing. For example, write "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of". Do not use needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions
          - Do not invent long or uncommon hyphenated compound words. Rephrase them as plain words, for example write "a value smaller than the limit" instead of "a smaller-than-the-limit value". Established compounds already in common use, such as "real-world" or "state-of-the-art", are acceptable
          - When referring to the same thing, use the exact same term or concept throughout, to avoid confusion. Do not introduce unnecessary terms and concepts. Only exception is that when the same term or concept is referred repeatedly, shorter references can be used when obvious and self-explanatory from context
          - Do not use em dashes or en dashes to connect sentences
          - Do not use punctuation like semicolons, colons, or parentheses to join or compress sentences
          - Do not use formatting like bold, italic, itemized lists, or enumerated lists, unless explicitly instructed
        3. In prose-heavy scenarios, for example Markdown and LaTeX, where linebreaks do not affect rendering, break lines between sentences at natural pauses to make diffs and editing easier. Never break in the middle of a sentence
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
          - Replace invented long or uncommon hyphenated compound words with plain phrasing, for example "a value smaller than the limit" instead of "a smaller-than-the-limit value". Leave established compounds already in common use, such as "real-world" or "state-of-the-art", unchanged
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
      };

      skills = {
        pdf = ''
          ---
          name: pdf
          description: Read and extract text from PDF files. Use when the user mentions PDFs or when you need to read a PDF file, especially when the Read tool fails on PDFs.
          ---

          # PDF Processing

          Use `pdftotext` (from poppler-utils) to extract text from PDFs:

          ```sh
          pdftotext <file> -
          ```

          This outputs to stdout. Use via Bash tool when the Read tool cannot handle a PDF file.
        '';

        document-conversion = ''
          ---
          name: document-conversion
          description: Convert between document formats (markdown, HTML, docx, LaTeX, etc.). Use when you need to read non-plain-text documents or convert between formats.
          ---

          # Document Conversion

          Use `pandoc` for document format conversion:

          ```sh
          pandoc input.md -o output.pdf
          pandoc input.docx -t markdown
          pandoc input.html -o output.docx
          ```

          Pandoc supports markdown, HTML, LaTeX, docx, PDF, epub, rst, and many more formats.
        '';

        structured-data = ''
          ---
          name: structured-data
          description: Process YAML, TOML, XML, and JSON files. Use when you need to query, transform, or convert between structured data formats.
          ---

          # Structured Data Processing

          Use `yq` (yq-go) for YAML/TOML/XML/JSON processing:

          ```sh
          yq '.key.nested' file.yaml
          yq -p toml '.section.key' file.toml
          yq -p xml '.root.element' file.xml
          yq -o json '.' file.yaml        # convert YAML to JSON
          yq -p json -o yaml '.' file.json # convert JSON to YAML
          ```
        '';
      };
    };
  };
}
