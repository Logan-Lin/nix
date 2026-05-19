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
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/macbook/system.nix ];
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations."imac" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/imac/system.nix ];
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
      "yanlin@macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/macbook/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@imac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/imac/home.nix ];
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
