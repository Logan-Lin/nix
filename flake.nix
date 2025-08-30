{
  description = "Default environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nixvim, claude-code, firefox-addons, nix-homebrew }:
  {
    darwinConfigurations."iMac" = nix-darwin.lib.darwinSystem {
      modules = [ 
        ./hosts/darwin/iMac
      ];
      specialArgs = { inherit nix-homebrew; };
    };

    darwinConfigurations."MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
        ./hosts/darwin/MacBook-Air
      ];
      specialArgs = { inherit nix-homebrew; };
    };

    homeConfigurations = {
      "yanlin@iMac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/iMac/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
      };

      "yanlin@MacBook-Air" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/MacBook-Air/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
      };
    };
  };
}
