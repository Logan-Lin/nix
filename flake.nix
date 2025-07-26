{
  description = "Default environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, claude-code }:
  let
    configuration = { pkgs, ... }: {
      environment.systemPackages =
        [ pkgs.vim
          pkgs.git
        ];

      nix.settings.experimental-features = "nix-command flakes";
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";

      programs.zsh.enable = true;
    };

    homeConfiguration = { pkgs, ... }: {
      imports = [ ./nvim.nix ./tmux.nix ];

      home.username = "yanlin";
      home.homeDirectory = "/Users/yanlin";
      home.stateVersion = "24.05";

      home.packages = with pkgs; [
        texlive.combined.scheme-full
        btop
        python312
        python312Packages.pip
        python312Packages.virtualenv
        lftp
        claude-code.packages.aarch64-darwin.claude-code
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        gitui
      ];

      fonts.fontconfig.enable = true;

      programs.home-manager.enable = true;

      programs.zsh = {
        enable = true;
        defaultKeymap = "viins";
        enableVteIntegration = true;
        sessionVariables = {
          COLORTERM = "truecolor";
        };
      };
    };
  in
  {
    darwinConfigurations."iMac" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    darwinConfigurations."mba" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    homeConfigurations.yanlin = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [ homeConfiguration ];
      extraSpecialArgs = { inherit claude-code; };
    };
  };
}
