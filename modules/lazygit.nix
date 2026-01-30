{ config, pkgs, lib, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        # Gruvbox dark theme colors
        theme = {
          # Light text on dark backgrounds
          lightTheme = false;
          
          # Active panel border color (bright blue)
          activeBorderColor = ["#458588" "bold"];
          
          # Inactive panel border color (dark gray)
          inactiveBorderColor = ["#504945"];
          
          # Search text color
          searchingActiveBorderColor = ["#fabd2f" "bold"];
          
          # Options text color
          optionsTextColor = ["#83a598"];
          
          # Selected line colors
          selectedLineBgColor = ["#3c3836"];
          selectedRangeBgColor = ["#3c3836"];
          
          # Cherry picked commit colors
          cherryPickedCommitBgColor = ["#458588"];
          cherryPickedCommitFgColor = ["#ebdbb2"];
          
          # Marked base commit for rebase
          markedBaseCommitBgColor = ["#fabd2f"];
          markedBaseCommitFgColor = ["#282828"];
          
          # Unstagged changes color
          unstagedChangesColor = ["#fb4934"];
          
          # Default text color
          defaultFgColor = ["#ebdbb2"];
        };
        
        # UI settings
        showFileTree = true;
        showListFooter = true;
        showRandomTip = false;
        showCommandLog = true;
        showBottomLine = true;
        showPanelJumps = true;
        commandLogSize = 8;
        splitDiff = "auto";
        
        # Screen mode (previously windowSize)
        screenMode = "normal";
        
        # Border style
        border = "rounded";
        
        # Commit length
        commitLength = {
          show = true;
        };
        
        # Mouse support
        mouseEvents = true;
        
        # Skip discard changes warning
        skipDiscardChangeWarning = false;
        
        # Skip stash warning
        skipStashWarning = false;
        
        # Side panel width
        sidePanelWidth = 0.3333;
        
        # Expand focused side panel
        expandFocusedSidePanel = false;
        
        # Main panel split mode
        mainPanelSplitMode = "flexible";
        
        # Enlarge active view
        enlargedSideViewLocation = "left";
        
        # Language
        language = "en";
        
        # Emoji
        nerdFontsVersion = "3";
        
        # Diff context size
        diffContextSize = 3;

        # Scroll amount per keystroke
        scrollHeight = 20;
      };
      
      # Git settings
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
        
        # Commit settings
        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };
        
        # Merge settings
        merging = {
          manualCommit = false;
          args = "";
        };
        
        # Skip hook prefix
        skipHookPrefix = "WIP";
        
        # Auto fetch
        autoFetch = true;
        autoRefresh = true;
        
        # Branch log cmd
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        
        # All branches log cmds (array format)
        allBranchesLogCmds = [
          "git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium"
        ];
        
        # Disable force pushing
        disableForcePushing = false;
        
        # Commit prefixes
        commitPrefixes = {};
        
        # Parse emoji
        parseEmoji = false;
        
        # Log settings
        log = {
          order = "topo-order";
          showGraph = "always";
          showWholeGraph = false;
        };
      };
      
      # Refresher settings
      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };
      
      # Update settings
      update = {
        method = "never";
      };
      
      # Confirmation on quit
      confirmOnQuit = false;
      
      # Quit on top level return
      quitOnTopLevelReturn = false;
      
      # Keybindings
      keybinding = {
        universal = {
          quit = "q";
          quit-alt1 = "<c-c>";
          return = "<esc>";
          quitWithoutChangingDirectory = "Q";
          togglePanel = "<tab>";
          prevItem = "<up>";
          nextItem = "<down>";
          prevItem-alt = "k";
          nextItem-alt = "j";
          prevPage = ",";
          nextPage = ".";
          scrollLeft = "H";
          scrollRight = "L";
          gotoTop = "<";
          gotoBottom = ">";
          toggleRangeSelect = "v";
          rangeSelectDown = "<s-down>";
          rangeSelectUp = "<s-up>";
          prevBlock = "<left>";
          nextBlock = "<right>";
          prevBlock-alt = "h";
          nextBlock-alt = "l";
          nextBlock-alt2 = "<tab>";
          prevBlock-alt2 = "<backtab>";
          jumpToBlock = ["1" "2" "3" "4" "5"];
          nextMatch = "n";
          prevMatch = "N";
          startSearch = "/";
          optionMenu = "?";
          optionMenu-alt1 = "x";
          select = "<space>";
          goInto = "<enter>";
          confirm = "<enter>";
          confirmInEditor = "<a-enter>";
          remove = "d";
          new = "n";
          edit = "e";
          openFile = "o";
          scrollUpMain = "<c-b>";
          scrollDownMain = "<c-f>";
          executeShellCommand = ":";
          createRebaseOptionsMenu = "m";
          
          # Diff view
          diffingMenu = "W";
          diffingMenu-alt = "<c-e>";
          copyToClipboard = "<c-o>";
          submitEditorText = "<enter>";
          extrasMenu = "@";
          toggleWhitespaceInDiffView = "<c-w>";
          increaseContextInDiffView = "}";
          decreaseContextInDiffView = "{";
        };
        
        # Status panel
        status = {
          checkForUpdate = "u";
          recentRepos = "<enter>";
          allBranchesLogGraph = "a";
        };
        
        # Files panel
        files = {
          commitChanges = "c";
          commitChangesWithoutHook = "w";
          amendLastCommit = "A";
          commitChangesWithEditor = "C";
          findBaseCommitForFixup = "<c-f>";
          confirmDiscard = "x";
          ignoreFile = "i";
          refreshFiles = "r";
          stashAllChanges = "s";
          viewStashOptions = "S";
          toggleStagedAll = "a";
          viewResetOptions = "D";
          fetch = "f";
          toggleTreeView = "`";
          openMergeOptions = "M";
          openStatusFilter = "<c-b>";
        };
        
        # Branches panel
        branches = {
          createPullRequest = "o";
          viewPullRequestOptions = "O";
          copyPullRequestURL = "<c-y>";
          checkoutBranchByName = "c";
          forceCheckoutBranch = "F";
          rebaseBranch = "r";
          renameBranch = "R";
          mergeIntoCurrentBranch = "M";
          viewGitFlowOptions = "i";
          fastForward = "f";
          createTag = "T";
          pushTag = "P";
          setUpstream = "u";
          fetchRemote = "f";
        };
        
        # Worktrees
        worktrees = {
          viewWorktreeOptions = "w";
        };
        
        # Commits panel
        commits = {
          squashDown = "s";
          renameCommit = "r";
          renameCommitWithEditor = "R";
          viewResetOptions = "g";
          markCommitAsFixup = "f";
          createFixupCommit = "F";
          squashAboveCommits = "S";
          moveDownCommit = "<c-j>";
          moveUpCommit = "<c-k>";
          amendToCommit = "A";
          resetCommitAuthor = "a";
          pickCommit = "p";
          revertCommit = "t";
          cherryPickCopy = "C";
          pasteCommits = "V";
          markCommitAsBaseForRebase = "B";
          tagCommit = "T";
          checkoutCommit = "<space>";
          resetCherryPick = "<c-R>";
          copyCommitAttributeToClipboard = "y";
          openLogMenu = "<c-l>";
          openInBrowser = "o";
          viewBisectOptions = "b";
          startInteractiveRebase = "i";
        };
        
        # Stash panel
        stash = {
          popStash = "g";
          renameStash = "r";
        };
        
        # Commit files panel
        commitFiles = {
          checkoutCommitFile = "c";
        };
        
        # Main panel
        main = {
          toggleSelectHunk = "a";
          pickBothHunks = "b";
          editSelectHunk = "E";
        };
        
        # Submodules panel
        submodules = {
          init = "i";
          update = "u";
          bulkMenu = "b";
        };
        
        # Commit message panel
        commitMessage = {
          commitMenu = "<c-o>";
        };
      };
      
      # OS settings
      os = {
        open = if pkgs.stdenv.isDarwin then "open {{filename}}" else "xdg-open {{filename}}";
        openLink = if pkgs.stdenv.isDarwin then "open {{link}}" else "xdg-open {{link}}";
      };
      
      # Disable startup popup
      disableStartupPopups = false;
      
      # Custom commands
      customCommands = [];
      
      # Services
      services = {};
      
      # Note to self
      notARepository = "prompt";
    };
  };
}
