{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    shntool
    cuetools
    flac
    unzip
    p7zip
    imagemagick
  ];

  programs.zsh.initContent = ''
    function audio2aac() {
      local dir="''${1:-.}"
      find "$dir" \( -name '*.flac' -o -name '*.mp3' -o -name '*.wav' -o -name '*.ogg' -o -name '*.wma' -o -name '*.aiff' \) -type f -print0 | xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./transcode/''${f%.*}.m4a"
        mkdir -p "$(dirname "$outfile")"
        ffmpeg -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile"
      ' _
    }

    function audio-normalize() {
      local dir="''${1:-.}"
      find "$dir" \( -name '*.flac' -o -name '*.mp3' -o -name '*.wav' -o -name '*.ogg' -o -name '*.wma' -o -name '*.aiff' \) -type f -print0 | xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./normalized/''${f%.*}.m4a"
        mkdir -p "$(dirname "$outfile")"
        ffmpeg -i "$f" -af loudnorm=I=-23:TP=-1.5:LRA=11 -c:a aac -b:a 128k -map_metadata 0 -c:v copy -movflags +faststart "$outfile"
      ' _
    }

    function video2av1() {
      local height="''${1:-720}"
      local dir="''${2:-.}"
      for f in "$dir"/**/*.(mp4|mkv|avi); do
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
      find "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | while read -r img; do
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

    function camera-copy() {
      local delete_source=0
      if [[ "$1" == "-d" || "$1" == "--delete" ]]; then
        delete_source=1
        shift
      fi

      if [[ $# -ne 2 ]]; then
        echo "Usage: camera-copy [-d|--delete] <source_dir> <destination>"
        echo ""
        echo "Copy photo and video files organized by date (YYYY-MM-DD/filename)"
        echo ""
        echo "Options:"
        echo "  -d, --delete    Delete source files after successful copy"
        echo ""
        echo "Examples:"
        echo "  camera-copy /media/sdcard/DCIM ~/Videos/imports"
        echo "  camera-copy -d /Volumes/CAMERA/DCIM user@nas:/backup/camera"
        return 1
      fi

      local SOURCE="$1"
      local DEST="$2"

      if [[ ! -d "$SOURCE" ]]; then
        echo "Error: Source directory does not exist: $SOURCE"
        return 1
      fi

      _get_media_date() {
        local file="$1"
        local raw_date

        raw_date=$(${pkgs.exiftool}/bin/exiftool -s3 -d '%Y-%m-%d' \
          -DateTimeOriginal -CreateDate -MediaCreateDate "$file" 2>/dev/null | head -1)

        if [[ -n "$raw_date" && "$raw_date" != "0000-00-00" ]]; then
          echo "$raw_date"
        else
          local mtime
          mtime=$(${pkgs.coreutils}/bin/stat -c '%Y' "$file" 2>/dev/null)
          ${pkgs.coreutils}/bin/date -d "@$mtime" +%Y-%m-%d
        fi
      }

      local copied=0
      local failed=0

      while IFS= read -r -d "" file; do
        local filename=$(basename "$file")

        [[ "$filename" == .* ]] && continue

        local date_dir=$(_get_media_date "$file")
        local year=''${date_dir:0:4}

        echo "[$date_dir] $filename"

        local rsync_opts=(-a --mkpath --progress --partial --ignore-existing)
        [[ $delete_source -eq 1 ]] && rsync_opts+=(--remove-source-files)

        if ${pkgs.rsync}/bin/rsync "''${rsync_opts[@]}" "$file" "$DEST/$year/$date_dir/$filename"; then
          ((copied++)) || true
        else
          echo "  Failed to copy: $file"
          ((failed++)) || true
        fi
      done < <(find "$SOURCE" -type f \( \
        -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mts" -o -iname "*.m2ts" -o -iname "*.avi" \
        -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" -o -iname "*.heif" \
        -o -iname "*.cr2" -o -iname "*.cr3" -o -iname "*.nef" -o -iname "*.arw" -o -iname "*.dng" -o -iname "*.raf" -o -iname "*.orf" -o -iname "*.rw2" \
        \) -print0)

      echo ""
      echo "=== Summary ==="
      echo "Copied: $copied"
      echo "Failed: $failed"
      [[ $delete_source -eq 1 ]] && echo "(source files removed)"
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
