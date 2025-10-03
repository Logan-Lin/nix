{ config, pkgs, lib, ... }:

{
  # Install TeXLive
  home.packages = with pkgs; [
    texlive.combined.scheme-full
  ];

  # Shell aliases for LaTeX compilation
  programs.zsh.shellAliases = {
    # Clean auxiliary LaTeX files
    mkpdf-clean = "latexmk -C";
  };

  # Shell functions for LaTeX compilation
  programs.zsh.initContent = ''
    # Build PDF with latexmk
    # Usage: mkpdf [file.tex]
    # If no argument provided, builds all .tex files in current directory
    function mkpdf() {
      local tex_file="''${1}"
      local output_dir="./out"

      if [[ -z "$tex_file" ]]; then
        # Build all .tex files in current directory
        local tex_files=(*.tex)
        if [[ ''${#tex_files[@]} -eq 0 ]] || [[ ! -f "''${tex_files[0]}" ]]; then
          echo "No .tex files found in current directory"
          return 1
        fi

        for file in "''${tex_files[@]}"; do
          echo "Building $file..."
          latexmk -pdf -bibtex -shell-escape -interaction=nonstopmode \
            -output-directory="$output_dir" -f "$file"
        done
      else
        if [[ ! -f "$tex_file" ]]; then
          echo "File not found: $tex_file"
          return 1
        fi

        latexmk -pdf -bibtex -shell-escape -interaction=nonstopmode \
          -output-directory="$output_dir" -f "$tex_file"
      fi
    }

    # Continuous compilation mode - watch and auto-rebuild
    # Usage: mkpdf-watch <file.tex>
    function mkpdf-watch() {
      local tex_file="''${1}"
      local output_dir="./out"

      if [[ -z "$tex_file" ]]; then
        echo "Usage: mkpdf-watch <file.tex>"
        return 1
      fi

      if [[ ! -f "$tex_file" ]]; then
        echo "File not found: $tex_file"
        return 1
      fi

      latexmk -pdf -pvc -view=none -shell-escape -interaction=nonstopmode \
        -output-directory="$output_dir" -f "$tex_file"
    }
  '';
}
