{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
  ];

  programs.zsh.initContent = ''
    function flac2aac() {
      local dir="''${1:-.}"
      find "$dir" -name '*.flac' -type f -print0 | xargs -0 -P4 -n1 sh -c '
        f="$1"
        outfile="./transcode/''${f%.flac}.m4a"
        mkdir -p "$(dirname "$outfile")"
        ffmpeg -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile"
      ' _
    }

    function video2av1() {
      local dir="''${1:-.}"
      for f in "$dir"/**/*.(mp4|mkv|avi); do
        if [[ -f "$f" ]]; then
          local outfile="./transcode/''${f%.*}.mkv"
          mkdir -p "$(dirname "$outfile")"
          ffmpeg -i "$f" \
            -c:v libsvtav1 -crf 30 -preset 6 \
            -vf "scale='min(480,iw)':-2" \
            -c:a copy \
            "$outfile"
        fi
      done
    }
  '';
}
