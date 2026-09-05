# TeX Live with the minted package fixed for Python 3.14.
# The latexminted 0.6.0 executable that TeX Live 2025 bundles with minted 3.7.0 subclasses argparse without accepting the `color` argument that Python 3.14 passes to every subparser, so loading minted fails with a TypeError.
# Upstream fixed this in latexminted 0.7.0, which requires minted.sty 3.8.0 and is not part of TeX Live 2025, so the same fix is applied to the bundled 0.6.0 wheel here.

{ pkgs, ... }:

let
  minted = pkgs.texlive.pkgs.minted;

  # The minted executable together with the wheels it loads, with the argparse fix applied to the latexminted wheel.
  latexminted = pkgs.runCommand "latexminted-0.6.0-python3.14"
    {
      nativeBuildInputs = [
        pkgs.unzip
        pkgs.zip
      ];
    }
    ''
      scripts="$out/scripts/minted"
      wheel=latexminted-0.6.0-py3-none-any.whl
      mkdir -p "$scripts" "$out/bin" unpacked

      cp ${minted.tex}/scripts/minted/latexminted.py ${minted.tex}/scripts/minted/*.whl "$scripts"/
      unzip -q "$scripts/$wheel" -d unpacked
      substituteInPlace unpacked/latexminted/cmdline.py \
        --replace-fail \
          "def __init__(self, *, prog: str):" \
          "def __init__(self, *, prog: str, **kwargs):" \
        --replace-fail \
          "formatter_class=argparse.RawTextHelpFormatter" \
          "formatter_class=argparse.RawTextHelpFormatter, **kwargs"

      chmod u+w "$scripts/$wheel"
      rm "$scripts/$wheel"
      find unpacked -exec touch -d @315532800 {} +
      (cd unpacked && zip -qrX "$scripts/$wheel" .)

      substitute ${minted.out}/bin/latexminted "$out/bin/latexminted" \
        --replace-fail "${minted.tex}/scripts/minted" "$scripts"
      chmod +x "$out/bin/latexminted"
    '';

  # TeX Live runs the executable from its own bin directory, which it puts first on PATH, so the fix has to be spliced into the environment itself.
  texlive = pkgs.texliveFull.overrideAttrs (old: {
    postBuild = old.postBuild + ''
      substituteInPlace "$out/bin/latexminted" \
        --replace-fail "${minted.out}/bin/latexminted" "${latexminted}/bin/latexminted"
    '';
  });
in
{
  home.packages = [ texlive ];
}
