# NOTE: Immich credentials file at: `~/.config/immich-env` with IMMICH_URL and IMMICH_APIKEY

{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    shntool
    cuetools
    flac
    zip
    unzip
    p7zip
    imagemagick
    immich-go
  ];

  programs.zsh.initContent = ''
    function audio2aac() {
      local dir="''${1:-.}"
      find "$dir" \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.wma' -o -iname '*.aiff' -o -iname '*.m4a' -o -iname '*.aac' \) -type f -print0 | xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./transcode/''${f%.*}.m4a"
        mkdir -p "$(dirname "$outfile")"
        ffmpeg -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile"
      ' _
    }

    function cuesplit() {
      local audio="$1"
      local cue="''${2:-''${audio%.*}.cue}"
      if [[ ! -f "$audio" ]]; then
        echo "Audio file not found: $audio" >&2
        return 1
      fi
      if [[ ! -f "$cue" ]]; then
        echo "Cue file not found: $cue" >&2
        return 1
      fi
      local enc=$(${pkgs.file}/bin/file --brief --mime-encoding "$cue")
      if [[ "$enc" != "utf-8" && "$enc" != "us-ascii" ]]; then
        local tmp=$(mktemp)
        iconv -f "$enc" -t UTF-8 "$cue" > "$tmp" && mv "$tmp" "$cue"
      fi
      local ext="''${audio##*.}"
      local fmt="''${ext:l}"
      mkdir -p ./tracks
      shnsplit -f "$cue" -t "%n - %t" -o "$fmt" -d ./tracks "$audio"
    }

    function image2webp() {
      local dir="''${1:-.}"
      find "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.heic' -o -iname '*.heif' \) | while read -r img; do
        outfile="''${img%.*}.webp"
        ${pkgs.imagemagick}/bin/magick "$img" -resize '1800>' -quality 82 "$outfile"
        echo "Converted: $img -> $outfile"
      done
    }

    function webp2png() {
      local dir="''${1:-.}"
      find "$dir" -type f -iname '*.webp' | while read -r img; do
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
          ffmpeg -i "$f" \
            -vf "$vf" \
            -quality 75 -compression_level 4 -loop 0 \
            "$outfile"
          echo "Converted: $f -> $outfile"
        fi
      done
    }

    function video2av1() {
      local height="''${1:-720}"
      local dir="''${2:-.}"
      for f in "$dir"/**/(#i)*.(mp4|mkv|avi); do
        if [[ -f "$f" ]]; then
          local outfile="./transcode/''${f%.*}.mkv"
          mkdir -p "$(dirname "$outfile")"
          ffmpeg -i "$f" \
            -c:v libsvtav1 -crf 30 -preset 6 \
            -vf "scale=-2:'min($height,ih)'" \
            -c:a copy \
            "$outfile"
        fi
      done
    }

    function photo-upload() {
      local envfile="$HOME/.config/immich-env"
      if [[ ! -f "$envfile" ]]; then
        echo "Missing $envfile" >&2
        return 1
      fi
      source "$envfile"
      if [[ -z "$IMMICH_URL" || -z "$IMMICH_APIKEY" ]]; then
        echo "IMMICH_URL and IMMICH_APIKEY must be set in $envfile" >&2
        return 1
      fi

      if [[ $# -eq 0 ]]; then
        echo "Usage: photo-upload <source_dir>" >&2
        return 1
      fi

      immich-go upload from-folder --server="$IMMICH_URL" --api-key="$IMMICH_APIKEY" "$1"
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

      mkdir -p "$dest"

      case "''${file:l}" in
        *.tar.gz|*.tgz)     tar -xzf "$file" -C "$dest" ;;
        *.tar.bz2|*.tbz2)   tar -xjf "$file" -C "$dest" ;;
        *.tar.xz|*.txz)     tar -xJf "$file" -C "$dest" ;;
        *.tar.zst|*.tzst)   tar --zstd -xf "$file" -C "$dest" ;;
        *.tar)              tar -xf "$file" -C "$dest" ;;
        *.gz)               gunzip -k "$file" ;;
        *.bz2)              bunzip2 -k "$file" ;;
        *.xz)               unxz -k "$file" ;;
        *.zip|*.cbz)        unzip -q "$file" -d "$dest" ;;
        *.7z)               7z x "$file" -o"$dest" ;;
        *.rar)              7z x "$file" -o"$dest" ;;
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
        gz)   tar -czf "''${name}.tar.gz" "$@" ;;
        bz2)  tar -cjf "''${name}.tar.bz2" "$@" ;;
        xz)   tar -cJf "''${name}.tar.xz" "$@" ;;
        zst)  tar --zstd -cf "''${name}.tar.zst" "$@" ;;
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
          tar -tf "$file" ;;
        *.zip|*.cbz)    unzip -l "$file" ;;
        *.7z)     7z l "$file" ;;
        *.rar)    7z l "$file" ;;
        *)        echo "Unknown archive format: $file" >&2; return 1 ;;
      esac
    }

  '';
}
