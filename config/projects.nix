{
  projects = {
    nix-config = {
      template = "basic";
      name = "nix";
      codePath = "/Users/yanlin/.config/nix";
      description = "Nix configuration";
    };

    homelab = {
      template = "basic";
      name = "homelab";
      codePath = "/Users/yanlin/Documents/Projects/Homelab-deploy";
      description = "Homelab Deployment";
    };

    blog = {
      template = "content";
      name = "blog";
      codePath = "/Users/yanlin/Documents/Projects/personal-blog";
      contentPath = "/Users/yanlin/Documents/Projects/personal-blog/content";
      description = "Personal blog project";
    };

    homepage = {
      template = "basic";
      name = "homepage";
      codePath = "/Users/yanlin/Documents/Projects/Homepage/";
      description = "Personal Homepage";
    };

    mdshortcut = {
      template = "research";
      name = "MDShortcut";
      codePath = "/Users/yanlin/Documents/Projects/Material Design Shortcut/MDShortcut-dev";
      paperPath = "/Users/yanlin/Documents/Projects/Material Design Shortcut/MDShortcut-paper";
      description = "Material Design Shortcut research project";
      server = "aicloud";
      remoteDir = "~/MDS";
    };

    daki3 = {
      template = "basic";
      name = "DAKI3";
      codePath = "/Users/yanlin/Documents/Projects/AI systems & infrastructure/Codes";
      description = "DAKI3 course Demo code";
    };

    diffdismatter = {
      template = "research";
      name = "DiffDisMatter";
      codePath = "/Users/yanlin/Documents/Projects/Inverse Design of Disordered Materials/DiffDisMatter-dev";
      paperPath = "/Users/yanlin/Documents/Projects/Inverse Design of Disordered Materials/mc-denoising-paper";
      description = "Inverse material design";
      server = "aicloud";
      remoteDir = "~/DiffDisMatter";
    };
  };
}
