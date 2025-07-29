{ pkgs, ... }:

{
  # Papis configuration
  home.file."Library/Application Support/papis/config".text = ''
    [settings]
    default-library = main
    editor = nvim
    opentool = open
    file-browser = open
    
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
  home.file."Library/Application Support/papis/templates/bibitem.template".text = ''
    {doc[title]} ({doc[year]}). {doc[author]}.
    Venue: {doc[journal]} {doc[booktitle]} {doc[eprinttype]} {doc[eprint]} {doc[eventtitle]}
    Tags: {doc[tags]}
    URL: {doc[url]}
    ---
  '';

  # Shell aliases for papis workflow
  programs.zsh.shellAliases = {
    # Bibliography formatting
    pals = "papis list --template \"$HOME/Library/Application Support/papis/templates/bibitem.template\"";
    
    # File operations
    pafile = "papis addto -f ~/Downloads/";
    paurl = "papis addto -u";
  };

  # Shell functions for papis workflow
  programs.zsh.initExtra = ''
    # Papis finder function - open document directory in Finder with query support
    pafinder() {
      local result=$(papis list "$@" | head -1)
      if [ -n "$result" ]; then
        open -R "$result"
      else
        echo "No documents found"
        return 1
      fi
    }
  '';
}
