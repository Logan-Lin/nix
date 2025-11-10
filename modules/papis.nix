{ pkgs, lib, ... }:

{
  # Install papis package
  home.packages = [
    (pkgs.papis.overridePythonAttrs (old: {
      doCheck = false;  # Skip tests due to Click incompatibility with Python 3.13
    }))
  ];
  # Papis configuration
  home.file.".config/papis/config".text = ''
    [settings]
    default-library = main
    editor = nvim
    opentool = evince
    
    # Document management
    ref-format = {doc[author]}{doc[year]}

    # Search and display
    sort-field = year
    sort-reverse = True
    match-format = {doc[tags]}{doc[author]}{doc[title]}{doc[year]}

    # Database and storage
    database-backend = papis
    use-git = False

    # Interface
    fzf-binary = fzf
    picktool = fzf
    
    [main]
    dir = ~/Documents/Library/papis
    
    # Local configuration for the main library
    local-config-file = .papisrc
  '';

  # Create the papis library directory
  home.activation.createPapisDir = ''
    mkdir -p ~/Documents/Library/papis
  '';

  # Papis bibliography template
  home.file.".config/papis/templates/bibitem.template".text = ''
    {doc[title]} ({doc[year]}). {doc[author]}.
    Venue: {doc[journal]} {doc[booktitle]} {doc[eprinttype]} {doc[eprint]} {doc[eventtitle]}
    Tags: {doc[tags]}
    URL: {doc[url]}
    ---
  '';

  # Papis BibTeX template
  home.file.".config/papis/templates/bibtex.template".text = ''
    @{doc[type]}{{{doc[ref]},
      author = {{{doc[author]}}},
      title = {{{doc[title]}}},
      year = {{{doc[year]}}},
      journal = {{{doc[journal]}}},
      booktitle = {{{doc[booktitle]}}},
      volume = {{{doc[volume]}}},
      number = {{{doc[number]}}},
      pages = {{{doc[pages]}}},
      doi = {{{doc[doi]}}},
      url = {{{doc[url]}}}
    }}
  '';

  # Papis citation template
  home.file.".config/papis/templates/citation.template".text = ''
    {doc[author]}. "{doc[title]}." {doc[journal]}{doc[booktitle]} ({doc[year]}).
  '';

  # Shell aliases for papis workflow
  programs.zsh.shellAliases = {
    # Bibliography formatting
    pals = "papis list --template \"$HOME/.config/papis/templates/bibitem.template\"";

    # Add new entry with bibtex
    paadd = "papis add --from bibtex";

    # BibTeX export
    pabib = "papis list --template \"$HOME/.config/papis/templates/bibtex.template\"";

    # Citation formatting
    pacite = "papis list --template \"$HOME/.config/papis/templates/citation.template\"";

    # File operations
    paurl = "papis addto -u";

    # Open documents
    paopen = "papis open";

    # Print document file path
    papwd = "papis list --file";

    # Cache management
    pareset = "papis cache reset";
  };

  # Shell functions for papis workflow
  programs.zsh.initContent = ''
    # Papis add file function - add file to existing document with proper parameter handling
    pafile() {
      if [ $# -lt 1 ]; then
        echo "Usage: pafile <filename> [query]"
        echo "Example: pafile paper.pdf                    # Interactive selection"
        echo "Example: pafile paper.pdf \"einstein relativity\"  # Direct match"
        echo "Example: pafile /path/to/paper.pdf \"quantum\"     # Absolute path"
        return 1
      fi
      
      local filename="$1"
      shift  # Remove first argument
      local query="$*"  # All remaining arguments as query (empty if none)
      
      # Check if filename is absolute path or relative to Downloads
      if [[ "$filename" == /* ]]; then
        # Absolute path
        if [ -n "$query" ]; then
          papis addto -f "$filename" "$query"
        else
          papis addto -f "$filename"
        fi
      else
        # Relative to Downloads
        if [ -n "$query" ]; then
          papis addto -f "$HOME/Downloads/$filename" "$query"
        else
          papis addto -f "$HOME/Downloads/$filename"
        fi
      fi
    }
    
    # Papis tag function - rewrite tags using hash-separated format
    patag() {
      if [ $# -ne 2 ]; then
        echo "Usage: patag \"tag1#tag2#tag3\" <query>"
        echo "Example: patag \"materials#ai4science\" amorphous"
        echo "Example: patag \"quantum#computing\" \"author:einstein\""
        return 1
      fi
      
      local tags_string="$1"
      local query="$2"
      
      # First, drop all existing tags
      papis tag --drop "$query"
      
      # Add each tag individually by splitting on #
      echo "$tags_string" | tr '#' '\n' | while read tag; do
        # Trim whitespace
        tag=$(echo "$tag" | xargs)
        if [ -n "$tag" ]; then
          papis tag --add "$tag" "$query"
        fi
      done
    }
  '';
}
