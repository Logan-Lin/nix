{
  force = true;
  default = "ddg";
  
  engines = {
    "ddg" = {
      urls = [{
        template = "https://duckduckgo.com/?q={searchTerms}";
      }];
      icon = "https://duckduckgo.com/favicon.ico";
      definedAliases = [ "@ddg" ];
    };
    
    "Nix Packages" = {
      urls = [{
        template = "https://search.nixos.org/packages";
        params = [
          { name = "channel"; value = "unstable"; }
          { name = "query"; value = "{searchTerms}"; }
        ];
      }];
      definedAliases = [ "@nixpkg" ];
    };

    "Linkding" = {
      urls = [{
        template = "https://link.nas.yanlincs.com/bookmarks";
        params = [
          { name = "q"; value = "{searchTerms}"; }
        ];
      }];
      definedAliases = [ "@link" ];
    };
    
    # Hide unwanted default search engines
    "google".metaData.hidden = true;
    "bing".metaData.hidden = true;
    "amazondotcom-us".metaData.hidden = true;
    "ebay".metaData.hidden = true;
    "wikipedia".metaData.hidden = true;
  };
}
