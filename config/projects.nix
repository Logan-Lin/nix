{ homeDirectory }:

let
  homePath = path: "${homeDirectory}/${path}";
in
{
  projects = {
    nix-config = {
      session = "nix";
      description = "Nix configuration";
      windows = [
        {
          name = "nix";
          path = "${homeDirectory}/.config/nix";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    homelab = {
      session = "homelab";
      description = "Homelab Deployment";
      windows = [
        {
          name = "homelab";
          path = homePath "Documents/Projects/Homelab-deploy";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    note = {
      session = "note";
      description = "Obsidian notes";
      windows = [
        {
          name = "note";
          path = homePath "Obsidian/Personal";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    acapro = {
      session = "aca-programs";
      description = "Academic programs";
      windows = [
        {
          name = "pro";
          path = homePath "Documents/Programs";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    blog = {
      session = "blog";
      description = "Personal blog project";
      windows = [
        {
          name = "code";
          path = homePath "Documents/Projects/personal-blog";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "content";
          path = homePath "Documents/Projects/personal-blog/content";
          ai = true;
          git = false;
        }
      ];
    };

    homepage = {
      session = "homepage";
      description = "Personal Homepage";
      windows = [
        {
          name = "homepage";
          path = homePath "Documents/Projects/Homepage";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    mdshortcut = {
      session = "MDShortcut";
      description = "Material design shortcut";
      windows = [
        {
          name = "code";
          path = homePath "Documents/Projects/Material Design Shortcut/MDShortcut-code";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "paper";
          path = homePath "Documents/Projects/Material Design Shortcut/MDShortcut-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    daki3c = {
      session = "DAKI3-C";
      description = "DAKI3 course";
      windows = [
        {
          name = "code";
          path = homePath "Documents/Projects/AI systems & infrastructure/Codes";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "slides";
          path = homePath "Documents/Projects/AI systems & infrastructure/Slides";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    daki3g = {
      session = "DAKI3-G";
      description = "DAKI3 group supervision";
      windows = [
        {
          name = "group";
          path = homePath "Documents/Projects/DAKI3 Semester Project Group";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    matmeet = {
      session = "MaterialMeet";
      description = "Material Meeting Slides";
      windows = [
        {
          name = "slides";
          path = homePath "Documents/Projects/Material Project Group Meeting";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    ddm = {
      session = "DiffDisMatter";
      description = "Inverse material design";
      windows = [
        {
          name = "code";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/DiffDisMatter-dev";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "paper";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/mc-denoising-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    ai4mat = {
      session = "AI4Mat";
      description = "AI4Material workshop";
      windows = [
        {
          name = "paper";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/AI4Mat-NeurIPS_2025";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

  };
}
