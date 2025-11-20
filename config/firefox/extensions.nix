args:

{
  packages = let
    firefox-addons = args.firefox-addons or null;
  in
    if firefox-addons != null then
      with firefox-addons.packages.${args.pkgs.stdenv.hostPlatform.system}; [
        ublock-origin
        linkding-extension
        vimium
        cookies-txt
        darkreader
      ]
    else [];
}
