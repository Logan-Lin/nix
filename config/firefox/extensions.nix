args:

{
  packages = let
    firefox-addons = args.firefox-addons or null;
    pkgs = args.pkgs;
    system = pkgs.stdenv.hostPlatform.system;

    buildFirefoxXpiAddon = firefox-addons.lib.${system}.buildFirefoxXpiAddon or null;

    zotero-connector = if buildFirefoxXpiAddon != null then
      buildFirefoxXpiAddon {
        pname = "zotero-connector";
        version = "5.0.193";
        addonId = "zotero@chnm.gmu.edu";
        url = "https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.193.xpi";
        sha256 = "jQLtVkFeRDZ8IiVGRKFcJ5b6AncXHnLuM5TS8vaAiQY=";
        meta = {};
      }
    else null;

  in
    (if firefox-addons != null then
      with firefox-addons.packages.${system}; [
        ublock-origin
        vimium
        cookies-txt
        darkreader
      ]
    else [])
    ++ (if zotero-connector != null then [ zotero-connector ] else []);
}
