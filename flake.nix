# Flake entry point for the Nix configuration.
# Declares the external inputs and discovers hosts automatically by reading the directories under each platform group in hosts/.
# For each host it produces a system configuration and a matching home-manager configuration, and it passes the flake inputs through to every module.

{
  description = "Default environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-bleed.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, ... }:
  let
    lib = nixpkgs.lib;

    hostsIn = dir:
      builtins.attrNames
        (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));

    darwinHosts = hostsIn ./hosts/darwin;
    nixosHosts = hostsIn ./hosts/nixos;

    mkDarwin = name: nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/${name}/system.nix ];
      specialArgs = { inherit inputs; };
    };

    mkNixos = name: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/nixos/${name}/system.nix ];
      specialArgs = { inherit inputs; };
    };

    mkHome = kind: system: name: home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [ ./hosts/${kind}/${name}/home.nix ];
      extraSpecialArgs = { inherit inputs; };
    };

    mkHomes = kind: system: hosts:
      lib.listToAttrs
        (map (name: lib.nameValuePair "yanlin@${name}" (mkHome kind system name)) hosts);
  in
  {
    darwinConfigurations = lib.genAttrs darwinHosts mkDarwin;

    nixosConfigurations = lib.genAttrs nixosHosts mkNixos;

    homeConfigurations =
      (mkHomes "darwin" "aarch64-darwin" darwinHosts)
      // (mkHomes "nixos" "x86_64-linux" nixosHosts);
  };
}
