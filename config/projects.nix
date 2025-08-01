{
  projects = {
    nix-config = {
      session = "nix";
      description = "Nix configuration";
      windows = [
        {
          name = "nix";
          path = "/Users/yanlin/.config/nix";
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
          path = "/Users/yanlin/Documents/Projects/Homelab-deploy";
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
          path = "/Users/yanlin/Obsidian/Personal";
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
          path = "/Users/yanlin/Documents/Programs";
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
          path = "/Users/yanlin/Documents/Projects/personal-blog";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "content";
          path = "/Users/yanlin/Documents/Projects/personal-blog/content";
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
          path = "/Users/yanlin/Documents/Projects/Homepage/";
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
          path = "/Users/yanlin/Documents/Projects/Material Design Shortcut/MDShortcut-code";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "paper";
          path = "/Users/yanlin/Documents/Projects/Material Design Shortcut/MDShortcut-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

    daki3 = {
      session = "DAKI3";
      description = "DAKI3 course";
      windows = [
        {
          name = "code";
          path = "/Users/yanlin/Documents/Projects/AI systems & infrastructure/Codes";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "slides";
          path = "/Users/yanlin/Documents/Projects/AI systems & infrastructure/Slides";
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
          path = "/Users/yanlin/Documents/Projects/Material Project Group Meeting";
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
          path = "/Users/yanlin/Documents/Projects/Inverse Design of Disordered Materials/DiffDisMatter-dev";
          ai = true;
          git = true;
          shell = true;
        }
        {
          name = "paper";
          path = "/Users/yanlin/Documents/Projects/Inverse Design of Disordered Materials/mc-denoising-paper";
          ai = true;
          git = true;
          shell = false;
        }
      ];
    };

  };
}
