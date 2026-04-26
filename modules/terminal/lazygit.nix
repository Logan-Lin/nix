{ config, pkgs, lib, ... }:

{
  home.packages = [ pkgs.delta ];

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          activeBorderColor = ["#458588" "bold"];
          inactiveBorderColor = ["#504945"];
          searchingActiveBorderColor = ["#fabd2f" "bold"];
          optionsTextColor = ["#83a598"];
          selectedLineBgColor = ["#3c3836"];
          selectedRangeBgColor = ["#3c3836"];
          cherryPickedCommitBgColor = ["#458588"];
          cherryPickedCommitFgColor = ["#ebdbb2"];
          markedBaseCommitBgColor = ["#fabd2f"];
          markedBaseCommitFgColor = ["#282828"];
          unstagedChangesColor = ["#fb4934"];
          defaultFgColor = ["#ebdbb2"];
        };

        showFileTree = true;
        showListFooter = true;
        showRandomTip = false;
        showCommandLog = true;
        showBottomLine = true;
        showPanelJumps = true;
        commandLogSize = 8;
        splitDiff = "auto";
        screenMode = "normal";
        border = "rounded";
        commitLength = {
          show = true;
        };
        mouseEvents = true;
        skipDiscardChangeWarning = false;
        skipStashWarning = false;
        sidePanelWidth = 0.3333;
        expandFocusedSidePanel = false;
        mainPanelSplitMode = "flexible";
        enlargedSideViewLocation = "left";
        language = "en";
        nerdFontsVersion = "3";
        diffContextSize = 3;
        scrollHeight = 20;
      };

      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];

        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };

        merging = {
          manualCommit = false;
          args = "";
        };

        skipHookPrefix = "WIP";
        autoFetch = true;
        autoRefresh = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        allBranchesLogCmds = [
          "git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium"
        ];
        disableForcePushing = false;
        commitPrefixes = {};
        parseEmoji = false;

        log = {
          order = "topo-order";
          showGraph = "always";
          showWholeGraph = false;
        };
      };

      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };

      update = {
        method = "never";
      };

      confirmOnQuit = false;
      quitOnTopLevelReturn = false;

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
          diffingMenu = "W";
          diffingMenu-alt = "<c-e>";
          copyToClipboard = "<c-o>";
          submitEditorText = "<enter>";
          extrasMenu = "@";
          toggleWhitespaceInDiffView = "<c-w>";
          increaseContextInDiffView = "}";
          decreaseContextInDiffView = "{";
        };

        status = {
          checkForUpdate = "u";
          recentRepos = "<enter>";
          allBranchesLogGraph = "a";
        };

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

        worktrees = {
          viewWorktreeOptions = "w";
        };

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

        stash = {
          popStash = "g";
          renameStash = "r";
        };

        commitFiles = {
          checkoutCommitFile = "c";
        };

        main = {
          toggleSelectHunk = "a";
          pickBothHunks = "b";
          editSelectHunk = "E";
        };

        submodules = {
          init = "i";
          update = "u";
          bulkMenu = "b";
        };

        commitMessage = {
          commitMenu = "<c-o>";
        };
      };

      os = {
        open = if pkgs.stdenv.isDarwin then "open {{filename}}" else "xdg-open {{filename}}";
        openLink = if pkgs.stdenv.isDarwin then "open {{link}}" else "xdg-open {{link}}";
      };

      disableStartupPopups = false;
      customCommands = [];
      services = {};
      notARepository = "prompt";
    };
  };
}
