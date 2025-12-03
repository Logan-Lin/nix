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

    note = {
      description = "Obsidian notes";
      windows = [
        {
          name = "";
          path = homePath "Documents/app-state/obsidian";
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
      description = "Personal blog";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/personal-blog";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

    homepage = {
      description = "Personal homepage";
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

    material = {
      description = "AI for Material";
      windows = [
        {
          name = "paper";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials/mdshortcut-ijcai26-paper";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "proj";
          path = homePath "Documents/Projects/Inverse Design of Disordered Materials";
          ai = false;
          git = false;
          shell = true;
        }
      ];
    };

    daki3 = {
      description = "DAKI3 2025 Semester";
      windows = [
        {
          name = "code";
          path = homePath "Documents/Projects/AI systems & infrastructure/Codes";
          ai = true;
          git = false;
          shell = true;
        }
        {
          name = "slide";
          path = homePath "Documents/Projects/AI systems & infrastructure/Slides";
          ai = true;
          git = false;
          shell = false;
        }
        {
          name = "group";
          path = homePath "Documents/Projects/DAKI3 Semester Project Group";
          ai = true;
          git = false;
          shell = false;
        }
      ];
    };

    dl4traj = {
      description = "Deep Learning for Trajectory";
      windows = [
        {
          name = "book";
          path = homePath "Documents/Projects/Deep Learning for Spatiotemporal Trajectories/DL4Traj-latex";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "proj";
          path = homePath "Documents/Projects/Deep Learning for Spatiotemporal Trajectories";
          ai = false;
          git = false;
          shell = true;
        }
      ];
    };

    micro-weight = {
      description = "Microscopic Weight Completion";
      windows = [
        {
          name = "paper";
          path = homePath "Documents/Projects/Microscopic Weights on Road Networks/MicroWeight-paper";
          ai = true;
          git = true;
          shell = false;
        }
        {
          name = "proj";
          path = homePath "Documents/Projects/Microscopic Weights on Road Networks";
          ai = false;
          git = false;
          shell = true;
        }
      ];
    };

  };
}
