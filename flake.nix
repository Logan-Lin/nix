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
    nix-casks = {
      url = "github:Logan-Lin/nix-casks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-bleed.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, ... }:
  {
    darwinConfigurations."sakurako" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/sakurako/system.nix ];
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations."himawari" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/himawari/system.nix ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."hanako" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/nixos/hanako/system.nix ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."nadeshiko" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/nixos/nadeshiko/system.nix ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."misaki" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/nixos/misaki/system.nix ];
      specialArgs = { inherit inputs; };
    };

    homeConfigurations = {
      "yanlin@sakurako" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/sakurako/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@himawari" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/himawari/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@hanako" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/hanako/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@nadeshiko" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/nadeshiko/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@misaki" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/misaki/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

    };
  };
}
