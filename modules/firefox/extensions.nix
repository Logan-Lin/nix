args:

{
  packages = let
    firefox-addons = args.inputs.firefox-addons or null;
    pkgs = args.pkgs;
    system = pkgs.stdenv.hostPlatform.system;

    buildFirefoxXpiAddon = firefox-addons.lib.${system}.buildFirefoxXpiAddon or null;

    zotero-connector = if buildFirefoxXpiAddon != null then
      buildFirefoxXpiAddon {
        pname = "zotero-connector";
        version = "5.0.195";
        addonId = "zotero@chnm.gmu.edu";
        url = "https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.195.xpi";
        sha256 = "gTfwxRyzJ3e92+bvvt52eXUE2mhRhPybq1gqKAdtwcg=";
        meta = {};
      }
    else null;

  in
    (if firefox-addons != null then
      with firefox-addons.packages.${system}; [
        ublock-origin
        vimium
        darkreader
        cookies-txt
      ]
    else [])
    ++ (if zotero-connector != null then [ zotero-connector ] else []);
}
