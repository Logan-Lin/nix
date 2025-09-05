{ homeDirectory }:

let
  homePath = path: "${homeDirectory}/${path}";
in
{
  projects = {
    nix = {
      description = "Nix configuration";
      windows = [
        {
          name = "";
          path = "${homeDirectory}/.config/nix";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    homelab = {
      description = "Homelab Deployment";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/Homelab-deploy";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    note = {
      description = "Obsidian notes";
      windows = [
        {
          name = "";
          path = homePath "Obsidian/Personal";
          ai = true;
          git = false;
          shell = false;
        }
      ];
    };

    acapro = {
      description = "Academic programs";
      windows = [
        {
          name = "";
          path = homePath "Documents/Programs";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    blog = {
      description = "Personal blog project";
      windows = [
        {
          name = "c";
          path = homePath "Documents/Projects/personal-blog";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "p";
          path = homePath "Documents/Projects/personal-blog/content";
          ai = true;
          git = false;
        }
      ];
    };

    homepage = {
      description = "Personal Homepage";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/Homepage";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    mdshortcut = {
      description = "Material design shortcut";
      windows = [
        {
          name = "c";
          path = homePath "Documents/Projects/Material Design Shortcut/MDShortcut-code";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "p";
          path = homePath "Documents/Projects/Material Design Shortcut/MDShortcut-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    daki3c = {
      description = "DAKI3 course";
      windows = [
        {
          name = "c";
          path = homePath "Documents/Projects/AI systems & infrastructure/Codes";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "s";
          path = homePath "Documents/Projects/AI systems & infrastructure/Slides";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "b";
          path = homePath "Documents/Projects/personal-blog/content/ai-system";
          ai = false;
          git = false;
          shell = false;
        }
      ];
    };

    daki3g = {
      description = "DAKI3 group supervision";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/DAKI3 Semester Project Group";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    matmeet = {
      description = "Material Meeting Slides";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/Material Project Group Meeting";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    ddm = {
      description = "Inverse material design";
      windows = [
        {
          name = "c";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/DiffDisMatter-dev";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "pc";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/AMDEN-code";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "p";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/mc-denoising-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    misc = {
      description = "Temp misc project";
      windows = [
        {
          name = "";
          path = homePath "Documents/Misc/2025/AI model train and infer-Wan";
          ai = true;
          git = false;
          shell = false;
        }
      ];
    };

  };
}
