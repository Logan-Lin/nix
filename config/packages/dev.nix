{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development and build tools
    texlive.combined.scheme-full
    python312
    uv
    
    # Database and data tools
    lazysql
    sqlite
  ];
}
