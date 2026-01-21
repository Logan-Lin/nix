{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    shntool
    cuetools
    flac
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
  '';
}
