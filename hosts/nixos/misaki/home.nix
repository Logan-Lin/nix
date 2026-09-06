# Home-manager configuration for misaki, a headless NixOS host.
# It keeps the Documents folder in sync with the user's other machines and carries the tooling used over an SSH session.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    httpie
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/agent/claude.nix
    ../../../modules/texlive.nix
  ];

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };
}
