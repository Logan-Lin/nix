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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nixvim, claude-code, firefox-addons }:
  let
    configuration = { pkgs, ... }: {
      imports = [
        ./system
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

    homeConfiguration = { pkgs, ... }: {
      imports = [ 
        nixvim.homeManagerModules.nixvim
        ./modules/nvim.nix 
        ./modules/tmux.nix 
        ./modules/zsh.nix 
        ./modules/ssh.nix
        ./modules/git.nix
        ./modules/lazygit.nix
        ./modules/papis.nix
        ./modules/termscp.nix
        ./modules/rsync.nix
        ./modules/btop.nix
        ./modules/firefox.nix
        ./modules/ghostty.nix
        ./modules/syncthing.nix
        ./config/fonts.nix
      ];

      nixpkgs.config.allowUnfree = true;

      home.username = "yanlin";
      home.homeDirectory = "/Users/yanlin";
      home.stateVersion = "24.05";

      home.packages = with pkgs; [
        texlive.combined.scheme-full
        python312
        uv
        lftp
        termscp
        httpie
        lazysql
        sqlite
        openssh
        papis
        claude-code.packages.aarch64-darwin.claude-code
        ncdu
        git-credential-oauth
        rsync
        gnumake
        zoxide
        delta
        maccy
        appcleaner
        iina
        keepassxc
        syncthing
        hidden-bar
      ];

      programs.home-manager.enable = true;


    };
  in
  {
    darwinConfigurations."iMac" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    darwinConfigurations."MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    homeConfigurations.yanlin = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [ homeConfiguration ];
      extraSpecialArgs = { inherit claude-code nixvim firefox-addons; };
    };
  };
}
