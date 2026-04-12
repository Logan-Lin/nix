{ pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.poppler-utils
      pkgs.pandoc
      pkgs.yq-go
    ];

    programs.claude-code = {
      enable = true;

      settings = {
        spinnerTipsEnabled = false;
        todoEnabled = true;
        autoCompactEnabled = true;
        autoMemoryEnabled = false;
        alwaysThinkingEnabled = true;
        feedbackSurveyRate = 0;
        env.CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
        prefersReducedMotion = true;
        promptSuggestionEnabled = false;
        effortLevel = "high";
        terminalProgressBarEnabled = false;
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

            "Bash(which:*)"
            "Bash(whereis:*)"
            "Bash(whoami)"
            "Bash(pwd)"
            "Bash(uname:*)"
            "Bash(date)"
            "Bash(echo:*)"
          ];

          deny = [
            "Bash(rm -rf:*)"
            "Bash(sudo:*)"
            "Bash(su:*)"
            "Bash(dd:*)"
            "Bash(mkfs:*)"
            "Bash(fdisk:*)"
          ];

          additionalDirectories = [
            "~/Documents/"
          ];
        };
      };

      memory.text = ''
        ## Environment
        1. System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        2. Projects may use flake + direnv for project-specific runtimes

        ## Writing Style
        1. Do not over-abuse comments in code, especially for self-explanatory blocks
        2. For text-heavy content, keep writing straightforward
          - Avoid using em dashes and en dashes to connect sentences
          - Do not abuse punctuation like semicolons/colons/parentheses to join or compress sentences, or formatting like bold/italic/itemize/enumeration (LaTeX or Markdown). Use them only when they genuinely help
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
          description: Convert between document formats (markdown, HTML, docx, LaTeX, etc.). Use when the user asks to convert documents or needs format transformation.
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
          description: Process YAML, TOML, XML, and JSON files. Use when the user needs to query, transform, or convert between structured data formats.
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
