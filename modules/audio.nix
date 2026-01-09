{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
  ];

  programs.zsh.initContent = ''
    function flac2aac() {
      local dir="''${1:-.}"
      for f in "$dir"/**/*.flac; do
        if [[ -f "$f" ]]; then
          local outfile="./transcode/''${f%.flac}.m4a"
          mkdir -p "$(dirname "$outfile")"
          ffmpeg -i "$f" -c:a aac -b:a 256k -movflags +faststart "$outfile"
        fi
      done
    }
  '';
}
