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
  let
    # Common system configuration shared across all Darwin systems
    commonSystemConfig = { pkgs, ... }: {
      imports = [
        ./modules/tailscale.nix
      ];

      environment.systemPackages = [
        # System-level packages only
      ];

      nix.settings.experimental-features = "nix-command flakes";
      nix.settings.substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];
      nix.settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";

      programs.zsh.enable = true;
    };

  in
  {
    darwinConfigurations."iMac" = nix-darwin.lib.darwinSystem {
      modules = [ 
        commonSystemConfig
        ./hosts/darwin/iMac
        nix-homebrew.darwinModules.nix-homebrew
      ];
    };

    darwinConfigurations."MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
        commonSystemConfig
        ./hosts/darwin/MacBook-Air
        nix-homebrew.darwinModules.nix-homebrew
      ];
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
