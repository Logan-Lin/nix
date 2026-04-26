{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    coreutils
    findutils
    gnutar
    gzip
    bzip2
    xz
    ffmpeg
    shntool
    cuetools
    flac
    zip
    unzip
    p7zip
    imagemagick
    poppler-utils
    exiftool
    pdftk
  ];

  programs.zsh.initContent = ''
    function audio2aac() {
      local dir="''${1:-.}"
      ${pkgs.findutils}/bin/find "$dir" \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.wma' -o -iname '*.aiff' -o -iname '*.m4a' -o -iname '*.aac' \) -type f -print0 | ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./transcode/''${f%.*}.m4a"
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$outfile")"
        ${pkgs.ffmpeg}/bin/ffmpeg -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile"
      ' _
    }

    function cuesplit() {
      local dir="''${1:-.}"
      ${pkgs.findutils}/bin/find "$dir" -type f -iname '*.cue' | while read -r cue; do
        local base="''${cue%.*}"
        local cuedir="''${cue:h}"
        local audio=""
        for ext in wav flac ape tta; do
          if [[ -f "$base.$ext" ]]; then
            audio="$base.$ext"
            break
          fi
        done
        if [[ -z "$audio" ]]; then
          echo "No matching audio for: $cue" >&2
          continue
        fi
        local enc=$(${pkgs.file}/bin/file --brief --mime-encoding "$cue")
        if [[ "$enc" != "utf-8" && "$enc" != "us-ascii" ]]; then
          local tmp=$(${pkgs.coreutils}/bin/mktemp)
          local converted=0
          if [[ "$enc" == "unknown-8bit" ]]; then
            for try_enc in CP932 Shift_JIS EUC-JP GB18030 BIG5; do
              if iconv -f "$try_enc" -t UTF-8 "$cue" > "$tmp" 2>/dev/null; then
                ${pkgs.coreutils}/bin/mv "$tmp" "$cue"
                converted=1
                break
              fi
            done
            if (( ! converted )); then
              echo "Could not detect encoding for: $cue" >&2
              ${pkgs.coreutils}/bin/rm -f "$tmp"
              continue
            fi
          else
            iconv -f "$enc" -t UTF-8 "$cue" > "$tmp" && ${pkgs.coreutils}/bin/mv "$tmp" "$cue"
          fi
        fi
        local afmt="''${audio##*.}"
        local outdir="$cuedir/tracks"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        ${pkgs.shntool}/bin/shnsplit -f "$cue" -t "%n - %t" -o "''${afmt:l}" -d "$outdir" "$audio"
      done
    }

    function image2webp() {
      local dir="''${1:-.}"
      ${pkgs.findutils}/bin/find "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.heic' -o -iname '*.heif' \) -print0 | ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="''${f%.*}.webp"
        ${pkgs.imagemagick}/bin/magick "$f" -resize "1800x1800>" -quality 82 "$outfile"
        echo "Converted: $f -> $outfile"
      ' _
    }

    function webp2png() {
      local dir="''${1:-.}"
      ${pkgs.findutils}/bin/find "$dir" -type f -iname '*.webp' | while read -r img; do
        outfile="''${img%.*}.png"
        ${pkgs.imagemagick}/bin/magick "$img" "$outfile"
        echo "Converted: $img -> $outfile"
      done
    }

    function video2webp() {
      local speed=1
      while [[ "$1" == --* ]]; do
        case "$1" in
          --speed) speed="$2"; shift 2 ;;
          *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
      done
      local dir="''${1:-.}"
      local vf="fps=10,scale='min(1280,iw)':-1"
      [[ "$speed" != "1" ]] && vf="setpts=PTS/$speed,$vf"
      for f in "$dir"/**/(#i)*.(mp4|mkv|mov); do
        if [[ -f "$f" ]]; then
          local outfile="''${f%.*}.webp"
          ${pkgs.ffmpeg}/bin/ffmpeg -i "$f" \
            -vf "$vf" \
            -quality 75 -compression_level 4 -loop 0 \
            "$outfile"
          echo "Converted: $f -> $outfile"
        fi
      done
    }

    function pdf2svg() {
      local dir="''${1:-.}"
      ${pkgs.findutils}/bin/find "$dir" -type f -iname '*.pdf' | while read -r pdf; do
        local outfile="''${pdf%.pdf}.svg"
        ${pkgs.poppler-utils}/bin/pdftocairo -svg "$pdf" "$outfile"
        echo "Converted: $pdf -> $outfile"
      done
    }

    function video2av1() {
      local height="''${1:-720}"
      local dir="''${2:-.}"
      for f in "$dir"/**/(#i)*.(mp4|mkv|avi); do
        if [[ -f "$f" ]]; then
          local outfile="./transcode/''${f%.*}.mkv"
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$outfile")"
          ${pkgs.ffmpeg}/bin/ffmpeg -i "$f" \
            -c:v libsvtav1 -crf 30 -preset 6 \
            -vf "scale=-2:'min($height,ih)'" \
            -c:a copy \
            "$outfile"
        fi
      done
    }

    function extract() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: extract <archive> [dest_dir]" >&2
        return 1
      fi

      local file="$1"
      local dest="''${2:-.}"

      if [[ ! -f "$file" ]]; then
        echo "File not found: $file" >&2
        return 1
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$dest"

      case "''${file:l}" in
        *.tar.gz|*.tgz)     ${pkgs.gnutar}/bin/tar -xzf "$file" -C "$dest" ;;
        *.tar.bz2|*.tbz2)   ${pkgs.gnutar}/bin/tar -xjf "$file" -C "$dest" ;;
        *.tar.xz|*.txz)     ${pkgs.gnutar}/bin/tar -xJf "$file" -C "$dest" ;;
        *.tar.zst|*.tzst)   ${pkgs.gnutar}/bin/tar --zstd -xf "$file" -C "$dest" ;;
        *.tar)              ${pkgs.gnutar}/bin/tar -xf "$file" -C "$dest" ;;
        *.gz)               ${pkgs.gzip}/bin/gunzip -k "$file" ;;
        *.bz2)              ${pkgs.bzip2}/bin/bunzip2 -k "$file" ;;
        *.xz)               ${pkgs.xz}/bin/unxz -k "$file" ;;
        *.zip|*.cbz)        ${pkgs.unzip}/bin/unzip -q "$file" -d "$dest" ;;
        *.7z)               ${pkgs.p7zip}/bin/7z x "$file" -o"$dest" ;;
        *.rar)              ${pkgs.p7zip}/bin/7z x "$file" -o"$dest" ;;
        *)
          echo "Unknown archive format: $file" >&2
          return 1
          ;;
      esac
    }

    function mktar() {
      if [[ $# -lt 2 ]]; then
        echo "Usage: mktar <format> <name> <files...>  (format: gz, bz2, xz, zst)" >&2
        return 1
      fi

      local fmt="$1"
      shift
      local name="$1"
      shift

      case "$fmt" in
        gz)   ${pkgs.gnutar}/bin/tar -czf "''${name}.tar.gz" "$@" ;;
        bz2)  ${pkgs.gnutar}/bin/tar -cjf "''${name}.tar.bz2" "$@" ;;
        xz)   ${pkgs.gnutar}/bin/tar -cJf "''${name}.tar.xz" "$@" ;;
        zst)  ${pkgs.gnutar}/bin/tar --zstd -cf "''${name}.tar.zst" "$@" ;;
        *)    echo "Unknown format: $fmt (use gz, bz2, xz, zst)" >&2; return 1 ;;
      esac
    }

    function lsarchive() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: lsarchive <archive>" >&2
        return 1
      fi

      local file="$1"
      case "''${file:l}" in
        *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tzst|*.tar)
          ${pkgs.gnutar}/bin/tar -tf "$file" ;;
        *.zip|*.cbz)    ${pkgs.unzip}/bin/unzip -l "$file" ;;
        *.7z)     ${pkgs.p7zip}/bin/7z l "$file" ;;
        *.rar)    ${pkgs.p7zip}/bin/7z l "$file" ;;
        *)        echo "Unknown archive format: $file" >&2; return 1 ;;
      esac
    }

  '';
}
