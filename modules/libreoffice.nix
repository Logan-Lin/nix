{ config, pkgs, ... }:

{
  # Install LibreOffice with Java support and dark mode wrapper
  # Workaround for LibreOffice dark mode on NixOS (Issue #310578)
  # LibreOffice ignores GTK dark theme due to GTK3 bug, so we wrap it with GTK_THEME=Adwaita:dark
  home.packages = with pkgs; [
    (pkgs.symlinkJoin {
      name = "libreoffice-dark";
      paths = [ libreoffice-fresh ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        for bin in $out/bin/*; do
          wrapProgram $bin \
            --set GTK_THEME Adwaita:dark
        done
      '';
    })
    jre  # Java Runtime Environment for LibreOffice features
  ];
}
