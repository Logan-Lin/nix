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
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nixvim, firefox-addons, nix-homebrew, disko }:
  {
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/macbook/system.nix ];
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations."imac" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/imac/system.nix ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."vps" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos/vps/system.nix
        ./hosts/nixos/vps/disk-config.nix
      ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."thinkpad" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos/thinkpad/system.nix
        ./hosts/nixos/thinkpad/disk-config.nix
      ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations."nfss" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos/nfss/system.nix
        ./hosts/nixos/nfss/disk-config.nix
      ];
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

      "yanlin@vps" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/vps/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@thinkpad" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/thinkpad/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      "yanlin@nfss" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/nfss/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

    };
  };
}
