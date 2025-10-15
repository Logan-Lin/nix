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
          name = "mds";
          path = homePath "Documents/Projects/Material Design Shortcut";
          ai = true;
          git = false;
          shell = false;
        }
        {
          name = "meet";
          path = homePath "Documents/Projects/Material Project Group Meeting";
          ai = true;
          git = false;
          shell = false;
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
          name = "";
          path = homePath "Documents/Projects/Deep Learning for Spatiotemporal Trajectories";
          ai = true;
          git = false;
          shell = true;
        }
      ];
    };

    bent = {
      description = "Trajectory Learning Benchmark";
      windows = [
        {
          name = "";
          path = homePath "Documents/Projects/Trajectory Modeling Benchmark/BenT-code/";
          ai = true;
          git = true;
          shell = true;
        }
      ];
    };

  };
}
