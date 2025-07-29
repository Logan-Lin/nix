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
    add-folder-name = {doc[author]}-{doc[year]}-{doc[title]}
    add-file-name = {doc[author]}-{doc[year]}-{doc[title]}
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
    papis-info = "papis list --template \"$HOME/Library/Application Support/papis/templates/bibitem.template\"";
    
    # File operations
    papis-add-file = "papis addto -f ~/Downloads/";
    papis-add-url = "papis addto -u";
    
    # Finder integration
    papis-finder = "open -R $(papis list)";
  };
}
