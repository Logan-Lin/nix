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
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    jovian-nixos.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nixvim, claude-code, firefox-addons, nix-homebrew, disko, jovian-nixos }:
  {
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/darwin/macbook/system.nix
      ];
      specialArgs = { inherit nix-homebrew; };
    };

    nixosConfigurations."hs" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nixos/hs/system.nix
        ./hosts/nixos/hs/disk-config.nix
      ];
    };

    nixosConfigurations."vps" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nixos/vps/system.nix
        ./hosts/nixos/vps/disk-config.nix
      ];
    };

    nixosConfigurations."thinkpad" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nixos/thinkpad/system.nix
        ./hosts/nixos/thinkpad/disk-config.nix
      ];
    };

    nixosConfigurations."deck" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        jovian-nixos.nixosModules.jovian
        ./hosts/nixos/deck/system.nix
        ./hosts/nixos/deck/disk-config.nix
      ];
    };

    homeConfigurations = {
      "yanlin@macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/darwin/macbook/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
      };

      "yanlin@hs" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/hs/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim; };
      };

      "yanlin@vps" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/vps/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim; };
      };

      "yanlin@thinkpad" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/thinkpad/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
      };

      "yanlin@deck" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./hosts/nixos/deck/home.nix ];
        extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
      };
    };
  };
}
