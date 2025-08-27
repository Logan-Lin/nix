{
  force = true;
  default = "ddg";
  
  # Uncomment to enable custom search engines
  # engines = {
  #   "Nix Packages" = {
  #     urls = [{
  #       template = "https://search.nixos.org/packages";
  #       params = [
  #         { name = "channel"; value = "unstable"; }
  #         { name = "query"; value = "{searchTerms}"; }
  #       ];
  #     }];
  #     icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  #     definedAliases = [ "@np" ];
  #   };
  #   
  #   "NixOS Wiki" = {
  #     urls = [{ template = "https://wiki.nixos.org/index.php?search={searchTerms}"; }];
  #     icon = "https://wiki.nixos.org/favicon.png";
  #     definedAliases = [ "@nw" ];
  #   };
  # };
}