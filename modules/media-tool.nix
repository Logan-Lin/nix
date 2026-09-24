{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    imagemagick
  ];

  programs.zsh.initContent = ''
    function audio2aac() {
      if [[ $# -lt 2 ]]; then
        echo "Usage: audio2aac <source> <dest>" >&2
        return 1
      fi
      local src="''${1%/}"
      local dst="$2"
      local base
      if [[ -f "$src" ]]; then
        base="''${src:h}"
      elif [[ -d "$src" ]]; then
        base="$src"
      else
        echo "Source not found: $src" >&2
        return 1
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dst"
      {
        if [[ -f "$src" ]]; then
          printf '%s\0' "$src"
        else
          ${pkgs.findutils}/bin/find "$src" -type f \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.wma' -o -iname '*.aiff' -o -iname '*.m4a' -o -iname '*.aac' \) -print0
        fi
      } | _BASE="$base" _DST="$dst" ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        rel="''${f#$_BASE/}"
        bn="''${rel##*/}"
        stem="''${bn%.*}"
        case "$rel" in
          */*) outdir="$_DST/''${rel%/*}" ;;
          *) outdir="$_DST" ;;
        esac
        outfile="$outdir/$stem.m4a"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        # -nostdin and the stdin redirect keep ffmpeg from consuming the file list that xargs is piping to the parallel workers.
        ${pkgs.ffmpeg}/bin/ffmpeg -nostdin -loglevel error -nostats -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile" >/dev/null </dev/null
        echo "Converted: $f -> $outfile"
      ' _
    }

    function image2webp() {
      if [[ $# -lt 2 ]]; then
        echo "Usage: image2webp <source> <dest>" >&2
        return 1
      fi
      local src="''${1%/}"
      local dst="$2"
      local base
      if [[ -f "$src" ]]; then
        base="''${src:h}"
      elif [[ -d "$src" ]]; then
        base="$src"
      else
        echo "Source not found: $src" >&2
        return 1
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dst"
      {
        if [[ -f "$src" ]]; then
          printf '%s\0' "$src"
        else
          ${pkgs.findutils}/bin/find "$src" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.heic' -o -iname '*.heif' \) -print0
        fi
      } | _BASE="$base" _DST="$dst" ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        rel="''${f#$_BASE/}"
        bn="''${rel##*/}"
        stem="''${bn%.*}"
        case "$rel" in
          */*) outdir="$_DST/''${rel%/*}" ;;
          *) outdir="$_DST" ;;
        esac
        outfile="$outdir/$stem.webp"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        ${pkgs.imagemagick}/bin/magick "$f" -resize "1800x1800>" -quality 82 "$outfile" >/dev/null
        echo "Converted: $f -> $outfile"
      ' _
    }

    function image2jpeg() {
      if [[ $# -lt 2 ]]; then
        echo "Usage: image2jpeg <source> <dest>" >&2
        return 1
      fi
      local src="''${1%/}"
      local dst="$2"
      local base
      if [[ -f "$src" ]]; then
        base="''${src:h}"
      elif [[ -d "$src" ]]; then
        base="$src"
      else
        echo "Source not found: $src" >&2
        return 1
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dst"
      {
        if [[ -f "$src" ]]; then
          printf '%s\0' "$src"
        else
          ${pkgs.findutils}/bin/find "$src" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.heic' -o -iname '*.heif' -o -iname '*.webp' \) -print0
        fi
      } | _BASE="$base" _DST="$dst" ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        rel="''${f#$_BASE/}"
        bn="''${rel##*/}"
        stem="''${bn%.*}"
        case "$rel" in
          */*) outdir="$_DST/''${rel%/*}" ;;
          *) outdir="$_DST" ;;
        esac
        outfile="$outdir/$stem.jpg"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        # JPEG has no alpha channel or animation, so take the first frame and flatten transparency onto white.
        ${pkgs.imagemagick}/bin/magick "''${f}[0]" -resize "1800x1800>" -background white -alpha remove -alpha off -quality 82 "$outfile" >/dev/null
        echo "Converted: $f -> $outfile"
      ' _
    }

    function webp2png() {
      if [[ $# -lt 2 ]]; then
        echo "Usage: webp2png <source> <dest>" >&2
        return 1
      fi
      local src="''${1%/}"
      local dst="$2"
      local base
      if [[ -f "$src" ]]; then
        base="''${src:h}"
      elif [[ -d "$src" ]]; then
        base="$src"
      else
        echo "Source not found: $src" >&2
        return 1
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dst"
      {
        if [[ -f "$src" ]]; then
          printf '%s\0' "$src"
        else
          ${pkgs.findutils}/bin/find "$src" -type f -iname '*.webp' -print0
        fi
      } | _BASE="$base" _DST="$dst" ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        rel="''${f#$_BASE/}"
        bn="''${rel##*/}"
        stem="''${bn%.*}"
        case "$rel" in
          */*) outdir="$_DST/''${rel%/*}" ;;
          *) outdir="$_DST" ;;
        esac
        outfile="$outdir/$stem.png"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        ${pkgs.imagemagick}/bin/magick "$f" "$outfile" >/dev/null
        echo "Converted: $f -> $outfile"
      ' _
    }

    function video2webp() {
      local speed=1
      while [[ "$1" == --* ]]; do
        case "$1" in
          --speed) speed="$2"; shift 2 ;;
          *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
      done
      if [[ $# -lt 2 ]]; then
        echo "Usage: video2webp [--speed N] <source> <dest>" >&2
        return 1
      fi
      local src="''${1%/}"
      local dst="$2"
      local base
      if [[ -f "$src" ]]; then
        base="''${src:h}"
      elif [[ -d "$src" ]]; then
        base="$src"
      else
        echo "Source not found: $src" >&2
        return 1
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dst"
      local vf="fps=10,scale='min(1280,iw)':-1"
      [[ "$speed" != "1" ]] && vf="setpts=PTS/$speed,$vf"
      {
        if [[ -f "$src" ]]; then
          printf '%s\0' "$src"
        else
          ${pkgs.findutils}/bin/find "$src" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \) -print0
        fi
      } | _BASE="$base" _DST="$dst" _VF="$vf" ${pkgs.findutils}/bin/xargs -0 -P4 -n1 sh -c '
        f="$1"
        rel="''${f#$_BASE/}"
        bn="''${rel##*/}"
        stem="''${bn%.*}"
        case "$rel" in
          */*) outdir="$_DST/''${rel%/*}" ;;
          *) outdir="$_DST" ;;
        esac
        outfile="$outdir/$stem.webp"
        ${pkgs.coreutils}/bin/mkdir -p "$outdir"
        ${pkgs.ffmpeg}/bin/ffmpeg -nostdin -loglevel error -nostats -i "$f" -vf "$_VF" -quality 75 -compression_level 4 -loop 0 "$outfile" >/dev/null </dev/null
        echo "Converted: $f -> $outfile"
      ' _
    }

  '';
}
