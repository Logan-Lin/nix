{ pkgs, ... }:

{
  # Papis configuration
  home.file.".config/papis/config".text = ''
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
}
