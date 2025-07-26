{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableVteIntegration = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
    };
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      
      # Nix helpers
      hm = "home-manager";
      hms = "home-manager switch --flake ~/.config/nix#yanlin";
    };
    
    initContent = ''
      # Load Powerlevel10k theme
      if [[ -f ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme ]]; then
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      fi
      
      # Load Powerlevel10k configuration (managed by Nix)
      source ~/.p10k.zsh
    '';
  };
  
  # Essential packages for enhanced zsh experience
  home.packages = with pkgs; [
    zsh-powerlevel10k
    fzf
    fd
    ripgrep
    bat
  ];
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  
  # Manage Powerlevel10k configuration
  home.file.".p10k.zsh".source = ./p10k.zsh;
}