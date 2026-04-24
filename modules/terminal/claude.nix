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

          additionalDirectories = [
            "~/Documents/"
          ];
        };
      };

      context = ''
        ## Environment
        1. System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        2. Projects may use flake + direnv for project-specific runtimes

        ## Writing Style
        1. Do not over-abuse comments in code, especially for self-explanatory blocks
        2. For text-heavy content, keep writing straightforward
          - Avoid using em dashes and en dashes to connect sentences
          - Do not abuse punctuation like semicolons/colons/parentheses to join or compress sentences, or formatting like bold/italic/itemize/enumeration (LaTeX or Markdown). Use them only when they genuinely help
        3. In prose-heavy files (Markdown, LaTeX, etc.) where linebreaks do not affect rendering, break lines between sentences at natural pauses to make diffs and editing easier. Never break in the middle of a sentence
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

          # By field
          curl -s 'https://api.openalex.org/works?search=QUERY&filter=primary_topic.field.display_name.search:Computer%20Science&per_page=10&select=id,doi,title,publication_year,cited_by_count&sort=cited_by_count:desc' | yq -P '.'
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

          OpenAlex stores abstracts as an inverted index in `abstract_inverted_index`. Reconstruct it, or use Semantic Scholar as a fallback for a plain text abstract:

          ```sh
          curl -s 'https://api.semanticscholar.org/graph/v1/paper/DOI:10.1234/example?fields=abstract' | yq -P '.abstract'
          ```

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

          ## Search NixOS options

          Query the search.nixos.org Elasticsearch backend. Replace QUERY with the search term.

          ```sh
          curl -s -X POST 'https://search.nixos.org/backend/latest-45-nixos-unstable/_search' \
            -u 'aWVSALXpZv:X8gPHnzL52wFEekuxsfQ9cSh' \
            -H 'Content-Type: application/json' \
            -d '{"size":10,"query":{"bool":{"must":[{"term":{"type":"option"}},{"dis_max":{"queries":[{"wildcard":{"option_name":{"value":"*QUERY*"}}},{"match":{"option_description":"QUERY"}}]}}]}},"_source":["option_name","option_type","option_default","option_description","option_source"]}' \
            | yq -P '.hits.hits[]._source | del(.option_description)'
          ```

          Include `option_description` in the yq output when details are needed. For the stable channel, replace `unstable` with `25.11`.

          ## Look up a specific NixOS option

          Use an exact term match on `option_name`:

          ```sh
          curl -s -X POST 'https://search.nixos.org/backend/latest-45-nixos-unstable/_search' \
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

          Use `nix eval` on the flake at `~/.config/nix`. Darwin configs are `macbook` and `imac`.

          List suboptions under a path:

          ```sh
          nix eval ~/.config/nix#darwinConfigurations.macbook.options.PATH --apply 'opt: builtins.attrNames opt'
          ```

          Get details for a specific option:

          ```sh
          nix eval ~/.config/nix#darwinConfigurations.macbook.options.OPTION.type.description
          nix eval ~/.config/nix#darwinConfigurations.macbook.options.OPTION.default
          nix eval ~/.config/nix#darwinConfigurations.macbook.options.OPTION.description
          ```

          ## Home Manager options via nix eval

          Useful for exploring option trees interactively. Home configs use the `"yanlin@HOST"` naming.

          ```sh
          nix eval ~/.config/nix#homeConfigurations.'"yanlin@macbook"'.options.programs.PROGRAM --apply 'opt: builtins.attrNames opt'
          nix eval ~/.config/nix#homeConfigurations.'"yanlin@macbook"'.options.programs.PROGRAM.enable.description
          ```

          ## Notes

          - The ES credentials are public, from the open-source nixos-search frontend
          - If ES queries return 404, the schema version (45) may have changed. Find the current version: `curl -s https://search.nixos.org/bundle.js | grep -o 'SchemaVersion:parseInt("[0-9]*")'`
        '';
      };
    };
  };
}
