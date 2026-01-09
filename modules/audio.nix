{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
  ];

  programs.zsh.initContent = ''
    function flac2aac() {
      local dir="''${1:-.}"
      for f in "$dir"/**/*.flac; do
        [[ -f "$f" ]] && ffmpeg -i "$f" -c:a aac -b:a 256k -movflags +faststart "''${f%.flac}.m4a"
      done
    }
  '';
}
