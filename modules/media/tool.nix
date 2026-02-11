{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    pdftk
    ffmpeg
    shntool
    cuetools
    flac
    unzip
    p7zip
    imagemagick
    exiftool
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

    function audio-normalize() {
      local dir="''${1:-.}"
      find "$dir" \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.wma' -o -iname '*.aiff' -o -iname '*.m4a' -o -iname '*.aac' \) -type f -print0 | xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./normalized/''${f%.*}.m4a"
        mkdir -p "$(dirname "$outfile")"
        ffmpeg -i "$f" -af loudnorm=I=-23:TP=-1.5:LRA=11 -c:a aac -b:a 128k -map_metadata 0 -c:v copy -movflags +faststart "$outfile"
      ' _
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

    function photo-move() {
      local mode=copy
      if [[ "$1" == "-d" || "$1" == "--delete" ]]; then
        mode=move; shift
      elif [[ "$1" == "-l" || "$1" == "--link" ]]; then
        mode=link; shift
      fi

      if [[ $# -ne 2 ]]; then
        echo "Usage: photo-move [-d|--delete|-l|--link] <source_dir> <destination>"
        echo "  -d, --delete    Move files instead of copying"
        echo "  -l, --link      Hardlink instead of copying"
        echo "  photo-move /Volumes/CAMERA/DCIM ~/DCIM"
        return 1
      fi

      local src="$1" dest="$2"

      if [[ ! -d "$src" ]]; then
        echo "Source not found: $src" >&2
        return 1
      fi

      local name raw_date target
      while IFS= read -r -d "" file; do
        name=$(basename "$file")
        [[ "$name" == .* ]] && continue

        raw_date=$(${pkgs.exiftool}/bin/exiftool -s3 -d '%Y-%m-%d' \
          -DateTimeOriginal -CreateDate -MediaCreateDate "$file" 2>/dev/null | head -1)

        if [[ ! "$raw_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || "$raw_date" == "0000-00-00" ]]; then
          raw_date=$(${pkgs.coreutils}/bin/date -d "@$(${pkgs.coreutils}/bin/stat -c '%Y' "$file")" +%Y-%m-%d)
        fi

        target="$dest/''${raw_date:0:4}/$raw_date"
        mkdir -p "$target"

        case $mode in
          move) mv "$file" "$target/$name" ;;
          link) ln "$file" "$target/$name" ;;
          *)    cp -a "$file" "$target/$name" ;;
        esac
      done < <(find "$src" -type f \( \
        -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mts" -o -iname "*.m2ts" -o -iname "*.avi" \
        -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" -o -iname "*.heif" \
        -o -iname "*.cr2" -o -iname "*.cr3" -o -iname "*.nef" -o -iname "*.arw" -o -iname "*.dng" -o -iname "*.raf" -o -iname "*.orf" -o -iname "*.rw2" \
        \) -print0)
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
        *.zip)              unzip -q "$file" -d "$dest" ;;
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
        *.zip)    unzip -l "$file" ;;
        *.7z)     7z l "$file" ;;
        *.rar)    7z l "$file" ;;
        *)        echo "Unknown archive format: $file" >&2; return 1 ;;
      esac
    }

  '';
}
