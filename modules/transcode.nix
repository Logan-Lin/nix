{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
  ];

  programs.zsh.initContent = ''
    function audio2aac() {
      local dir="''${1:-.}"
      for f in "$dir"/**/*.(flac|mp3|wav|ogg|wma|aiff)(N); do
        if [[ -f "$f" ]]; then
          local outfile="./transcode/''${f%.*}.m4a"
          mkdir -p "$(dirname "$outfile")"
          ffmpeg -i "$f" -vn -c:a aac -b:a 256k -movflags +faststart "$outfile"
        fi
      done
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
  '';
}
