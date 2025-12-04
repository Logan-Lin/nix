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

      mkdir -p "$output_dir"

      _mkpdf_build() {
        local file="$1"
        local log_file="$output_dir/''${file%.tex}.log"

        printf "Building %s... " "$file"
        if latexmk -pdf -bibtex -shell-escape -interaction=nonstopmode \
            -output-directory="$output_dir" -f "$file" > "$log_file" 2>&1; then
          local basename="''${file%.tex}"
          if [[ -f "$output_dir/$basename.pdf" ]]; then
            cp "$output_dir/$basename.pdf" "./"
            echo "done"
            return 0
          fi
        fi
        echo "failed (see $log_file)"
        tail -20 "$log_file"
        return 1
      }

      if [[ -z "$tex_file" ]]; then
        local found=0
        for file in *.tex(N); do
          found=1
          _mkpdf_build "$file"
        done
        if [[ $found -eq 0 ]]; then
          echo "No .tex files found in current directory"
          return 1
        fi
      else
        if [[ ! -f "$tex_file" ]]; then
          echo "File not found: $tex_file"
          return 1
        fi
        _mkpdf_build "$tex_file"
      fi
    }

    # Generate standalone PDF from LaTeX equation
    # Usage: mksvg <equation> <filename>
    # Example: mksvg 'E = mc^2' energy
    function mksvg() {
      local equation="''${1}"
      local filename="''${2}"

      if [[ -z "$equation" ]] || [[ -z "$filename" ]]; then
        echo "Usage: mksvg <equation> <filename>"
        echo "Example: mksvg 'E = mc^2' energy"
        return 1
      fi

      printf '%s\n' "$equation" > "''${filename}.texeq"

      local temp_tex="''${filename}_temp.tex"
      {
        printf '%s\n' '\documentclass{standalone}'
        printf '%s\n' '\usepackage{amsmath}'
        printf '%s\n' '\usepackage{amssymb}'
        printf '%s\n' '\begin{document}'
        printf '%s%s%s\n' '$' "$equation" '$'
        printf '%s\n' '\end{document}'
      } > "$temp_tex"

      pdflatex -interaction=nonstopmode "$temp_tex" > /dev/null 2>&1

      if [[ -f "''${filename}_temp.pdf" ]]; then
        mv "''${filename}_temp.pdf" "''${filename}.pdf"
        echo "Generated ''${filename}.pdf"
      else
        echo "Failed to generate PDF"
        rm -f "$temp_tex"
        return 1
      fi

      rm -f "$temp_tex" "''${filename}_temp.aux" "''${filename}_temp.log"
    }

    # Regenerate PDFs from all .texeq files in current directory
    function mksvg-all() {
      local found=0
      for file in *.texeq(N); do
        found=1
        local filename="''${file%.texeq}"
        local equation="$(cat "$file")"
        echo "Regenerating ''${filename}.pdf..."
        mksvg "$equation" "$filename"
      done
      if [[ $found -eq 0 ]]; then
        echo "No .texeq files found in current directory"
        return 1
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

      local basename="''${tex_file%.tex}"

      latexmk -pdf -pvc -view=none -shell-escape -interaction=nonstopmode \
        -output-directory="$output_dir" \
        -e "\$success_cmd = 'cp $output_dir/$basename.pdf ./';" \
        "$tex_file"
    }
  '';
}
