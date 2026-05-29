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
          CLAUDE_CODE_EFFORT_LEVEL = "max";
        };
        prefersReducedMotion = true;
        promptSuggestionEnabled = false;
        skipAutoPermissionPrompt = true;
        effortLevel = "xhigh";
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
            "Bash(rm -rf:*)"
            "Bash(sudo:*)"
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
        2. Projects may use flake + direnv for project-specific runtimes

        ## Writing Style
        1. Do not write code comments unless the user's prompt explicitly instructs you to. When instructed, keep them concise and in plain text, without fancy formatting
        2. For any natural language text content, such as notes, reports, papers, messages, and code comments/documents, keep writing straightforward, and follow the detailed rules below, unless the user's prompt explicitly instructs otherwise
          - Use plain and direct phrasing. For example, write "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of". Do not use needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions
          - When referring to the same thing, use the exact same term or concept throughout, to avoid confusion. Do not introduce unnecessary terms and concepts. Only exception is that when the same term or concept is referred repeatedly, shorter references can be used when obvious and self-explanatory from context
          - Do not use em dashes or en dashes to connect sentences
          - Do not use punctuation like semicolons, colons, or parentheses to join or compress sentences
          - Do not use formatting like bold, italic, itemized lists, or enumerated lists
        3. In prose-heavy scenarios, for example block documentation of code, Markdown, and LaTeX, where linebreaks do not affect rendering, break lines between sentences at natural pauses to make diffs and editing easier. Never break in the middle of a sentence
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
          allowed-tools: Read, Edit
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
          - Do not use em dashes or en dashes to connect sentences. Split into separate sentences or rephrase
          - Do not use semicolons, colons, or parentheses to join or compress sentences. Rewrite as flowing prose with separate sentences
          - When referring to the same thing, use the exact same term throughout. Remove unnecessary terms and concepts. The only exception is that shorter references can be used when the full term has been established and the short form is obvious from context

          Fix all issues directly in the file using the Edit tool. After editing, provide a brief summary of the changes made. Do not alter the underlying meaning. Only adjust wording, phrasing, and formatting to meet the rules.
        '';

        fact-check = ''
          ---
          description: Check the target file for factual errors against reputable sources
          allowed-tools: Read, Edit, WebSearch, WebFetch
          argument-hint: <file>
          ---

          ## Task

          Read the file provided in $ARGUMENTS and check it for factual errors:
          - Identify concrete factual claims (names, dates, numbers, attributions, definitions, events, technical specifications, etc.)
          - Verify each claim against reputable and relatively recent sources via WebSearch and WebFetch. Prefer primary sources, official documentation, peer-reviewed publications, and well-established outlets. Avoid relying on a single low-quality source
          - Skip opinions, subjective statements, and unverifiable claims

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

        academic-search = ''
          ---
          name: academic-search
          description: Search for academic papers, scholarly articles, research publications, and citations. Use when you want to find papers, look up a DOI, search by author, explore citations, or do a literature search.
          ---

          # Academic Paper Search

          Use the OpenAlex API via `curl` and parse results with `yq`.

          ## Search for papers

          ```sh
          curl -s 'https://api.openalex.org/works?search=QUERY&per_page=10&select=id,doi,title,authorships,publication_year,cited_by_count,open_access,primary_location&sort=cited_by_count:desc' | yq -P '.'
          ```

          URL-encode the query string. Use `sort=publication_date:desc` for most recent results instead.

          ## Filter by author, year, or field

          Add filters with `&filter=`:

          ```sh
          # By author name
          curl -s 'https://api.openalex.org/works?filter=raw_author_name.search:Hinton&per_page=10&select=id,doi,title,publication_year,cited_by_count&sort=cited_by_count:desc' | yq -P '.'

          # By year range
          curl -s 'https://api.openalex.org/works?search=QUERY&filter=publication_year:2020-2024&per_page=10&select=id,doi,title,authorships,publication_year,cited_by_count&sort=cited_by_count:desc' | yq -P '.'

          # By field (use the numeric field id from https://api.openalex.org/fields)
          # Common ids: Computer Science=17, Mathematics=26, Physics and Astronomy=31, Engineering=22, Medicine=27
          curl -s 'https://api.openalex.org/works?search=QUERY&filter=primary_topic.field.id:fields/17&per_page=10&select=id,doi,title,publication_year,cited_by_count&sort=cited_by_count:desc' | yq -P '.'
          ```

          Filters can be combined with commas: `filter=publication_year:>2020,raw_author_name.search:Vaswani`.

          ## Look up a specific paper by DOI

          ```sh
          curl -s 'https://api.openalex.org/works/doi:10.1234/example?select=id,doi,title,authorships,publication_year,cited_by_count,open_access,abstract_inverted_index,primary_location,referenced_works' | yq -P '.'
          ```

          ## Find papers that cite a given paper

          Use the OpenAlex work ID (e.g., W2741809807) from search results:

          ```sh
          curl -s 'https://api.openalex.org/works?filter=cites:W2741809807&per_page=10&select=id,doi,title,publication_year,cited_by_count&sort=cited_by_count:desc' | yq -P '.'
          ```

          ## Get abstract

          OpenAlex stores abstracts as an inverted index in `abstract_inverted_index`. Reconstruct it to get the plain text abstract.

          ## Access full text

          Check `open_access.oa_url` from search results for a free PDF link. Use the `pdf` skill to read downloaded PDFs.

          ## Presentation

          Present results as a table with: title, authors (first author et al.), year, citation count, and DOI link.
        '';

        nix-search = ''
          ---
          name: nix-search
          description: Search NixOS options, Home Manager options, nix-darwin options, and nixpkgs packages. Use when you need to look up Nix module options, find packages, or check option types, defaults, and module source.
          ---

          # Nix Options and Package Search

          The user's config flake is at `~/.config/nix` with NixOS, nix-darwin, and Home Manager.

          ## NixOS options via Elasticsearch backend

          The backend URL is `https://search.nixos.org/backend/latest-<SCHEMA>-nixos-<CHANNEL>` where `<CHANNEL>` is `unstable` or a release like `25.11`, and `<SCHEMA>` is a version integer that drifts over time. Look up the current schema once per session and reuse it:

          ```sh
          curl -s https://search.nixos.org/bundle.js | grep -oE 'SchemaVersion:parseInt\("[0-9]+"\)' | grep -oE '[0-9]+'
          ```

          Substitute the result for `<SCHEMA>` in the URLs below.

          ### Search options

          Replace QUERY with the search term:

          ```sh
          curl -s -X POST 'https://search.nixos.org/backend/latest-<SCHEMA>-nixos-unstable/_search' \
            -u 'aWVSALXpZv:X8gPHnzL52wFEekuxsfQ9cSh' \
            -H 'Content-Type: application/json' \
            -d '{"size":10,"query":{"bool":{"must":[{"term":{"type":"option"}},{"dis_max":{"queries":[{"wildcard":{"option_name":{"value":"*QUERY*"}}},{"match":{"option_description":"QUERY"}}]}}]}},"_source":["option_name","option_type","option_default","option_description","option_source"]}' \
            | yq -P '.hits.hits[]._source | del(.option_description)'
          ```

          Include `option_description` in the yq output when details are needed.

          ### Look up a specific option

          Use an exact term match on `option_name`:

          ```sh
          curl -s -X POST 'https://search.nixos.org/backend/latest-<SCHEMA>-nixos-unstable/_search' \
            -u 'aWVSALXpZv:X8gPHnzL52wFEekuxsfQ9cSh' \
            -H 'Content-Type: application/json' \
            -d '{"size":1,"query":{"bool":{"must":[{"term":{"type":"option"}},{"term":{"option_name":"OPTION_NAME"}}]}},"_source":["option_name","option_type","option_default","option_example","option_description","option_source"]}' \
            | yq -P '.hits.hits[]._source'
          ```

          The `option_source` field gives the module path in nixpkgs. View source at `https://github.com/NixOS/nixpkgs/blob/master/OPTION_SOURCE`.

          ## Search nixpkgs packages

          ```sh
          nix search nixpkgs QUERY --json | yq -P '.'
          ```

          ## Search Home Manager options

          Filter the options JSON from home-manager-options.extranix.com. Replace PATTERN with a regex.

          ```sh
          curl -s 'https://home-manager-options.extranix.com/data/options-master.json' \
            | yq -P '[.options[] | select(.title | test("PATTERN"))] | .[:10] | .[] | {"name": .title, "type": .type, "default": .default, "description": .description}'
          ```

          For a specific option, use exact match: `select(.title == "OPTION_NAME")`. For stable releases, replace `master` with `release-25.11`.

          ## Search nix-darwin options

          Use `nix eval` on the flake at `~/.config/nix`. Replace HOST below with a darwin host attr name.

          List suboptions under a path:

          ```sh
          nix eval ~/.config/nix#darwinConfigurations.HOST.options.PATH --apply 'opt: builtins.attrNames opt'
          ```

          Get details for a specific option:

          ```sh
          nix eval ~/.config/nix#darwinConfigurations.HOST.options.OPTION.type.description
          nix eval ~/.config/nix#darwinConfigurations.HOST.options.OPTION.default
          nix eval ~/.config/nix#darwinConfigurations.HOST.options.OPTION.description
          ```

          ## Home Manager options via nix eval

          Useful for exploring option trees interactively. Home configs use the `"yanlin@HOST"` naming.

          ```sh
          nix eval ~/.config/nix#homeConfigurations.'"yanlin@HOST"'.options.programs.PROGRAM --apply 'opt: builtins.attrNames opt'
          nix eval ~/.config/nix#homeConfigurations.'"yanlin@HOST"'.options.programs.PROGRAM.enable.description
          ```

          ## Notes

          - The ES credentials are public, from the open-source nixos-search frontend
        '';
      };
    };
  };
}
