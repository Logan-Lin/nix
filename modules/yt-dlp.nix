{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.yt-dlp-custom;
in

{
  options.programs.yt-dlp-custom = {
    enable = mkEnableOption "yt-dlp video downloader configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.yt-dlp;
      example = "pkgs.yt-dlp";
      description = "yt-dlp package to use";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "~/Downloads/Videos";
      example = "/mnt/storage/videos";
      description = "Base directory for downloaded videos";
    };

    subscriptions = {
      enable = mkEnableOption "RSS subscription checking for automatic video downloads";

      feeds = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [
          "https://www.youtube.com/feeds/videos.xml?channel_id=UCRHXUZ0BxbkU2MYZgsuFgkQ"
        ];
        description = "List of YouTube RSS feed URLs to monitor for new videos";
      };

      interval = mkOption {
        type = types.str;
        default = "hourly";
        example = "*-*-* */4:00:00";
        description = "Systemd timer schedule for checking subscriptions";
      };

      randomDelay = mkOption {
        type = types.str;
        default = "0";
        example = "30m";
        description = "Random delay before running subscription check (e.g., '30m', '1h')";
      };

      maxVideosPerFeed = mkOption {
        type = types.int;
        default = 5;
        example = 10;
        description = "Maximum number of videos to process per feed (newest first)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install yt-dlp, deno, and ffmpeg
    # Deno is required for YouTube downloads (GitHub issue #14404)
    home.packages = with pkgs; [
      cfg.package
      deno     # Required for YouTube downloads due to JS challenges
      ffmpeg
    ] ++ lib.optionals cfg.subscriptions.enable [
      libxml2  # For xmllint to parse RSS feeds
    ];

    # Cookie files - managed by Nix (read-only)
    # The download function copies these to temp files when needed
    home.file.".config/yt-dlp/cookies-youtube.txt" = {
      source = ../config/yt-dlp/cookies-youtube.txt;
    };
    home.file.".config/yt-dlp/cookies-bilibili.txt" = {
      source = ../config/yt-dlp/cookies-bilibili.txt;
    };

    # Create yt-dlp configuration file
    home.file.".config/yt-dlp/config".text = ''
      # Quality settings
      --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
      --merge-output-format mp4
      
      # Download options
      --no-playlist
      --embed-thumbnail
      --write-thumbnail
      --write-description
      --write-info-json
      
      # File naming and organization
      # Allow unicode characters in filenames for Chinese/Japanese content
      
      # Performance
      --concurrent-fragments 4
      --retries 10
      --fragment-retries 10
      
      # SponsorBlock for YouTube
      --sponsorblock-mark all
      
      # User agent
      --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    '';

    # Shell aliases for different download types
    programs.zsh.shellAliases = {
      # YouTube downloads
      dl-yt = "download-youtube";
      dl-yt-p = "download-youtube-playlist";
      
      # Bilibili downloads  
      dl-bili = "download-bilibili";
      dl-bili-p = "download-bilibili-playlist";
      
      # Help
      dl-help = "download-help";
    } // lib.optionalAttrs cfg.subscriptions.enable {
      # YouTube subscription management
      dl-subs-yt = "check-youtube-subscriptions";
    };

    programs.zsh.initContent = ''
      # Base download directory
      DOWNLOAD_DIR="${cfg.downloadDir}"
      DOWNLOAD_DIR="''${DOWNLOAD_DIR/#\~/$HOME}"
      
      # Retry configuration
      MAX_RETRIES=10
      BASE_DELAY=60
      
      # Helper function to create writable cookie file
      _setup_temp_cookies() {
        local cookies_file="$1"
        if [[ -f "$cookies_file" ]]; then
          local temp_cookies="/tmp/yt-dlp-cookies-$$.txt"
          cp "$cookies_file" "$temp_cookies" 2>/dev/null
          chmod 644 "$temp_cookies" 2>/dev/null
          echo "$temp_cookies"
        else
          echo ""
        fi
      }
      
      # Retry wrapper function with exponential backoff
      _retry_download() {
        local cmd="$1"
        local attempt=1
        local delay=$BASE_DELAY
        
        while [[ $attempt -le $MAX_RETRIES ]]; do
          echo "Attempt $attempt/$MAX_RETRIES..."
          
          eval "$cmd"
          local result=$?
          
          if [[ $result -eq 0 ]]; then
            return 0
          fi
          
          if [[ $attempt -lt $MAX_RETRIES ]]; then
            echo "Download failed, retrying in ''${delay}s..."
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
          else
            echo "All retry attempts failed"
          fi
          
          ((attempt++))
        done
        
        return 1
      }
      
      # YouTube single video download
      download-youtube() {
        local url="$*"
        if [[ -z "$url" ]]; then
          echo "Usage: dl-yt <url>"
          return 1
        fi
        
        local cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"
        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local output_template="$DOWNLOAD_DIR/YouTube/%(uploader|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading YouTube video..."
        echo "Output directory: $DOWNLOAD_DIR/YouTube"
        
        local cmd="yt-dlp"
        [[ -n "$temp_cookies" ]] && cmd="$cmd --cookies '$temp_cookies'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"
        
        if _retry_download "$cmd"; then
          echo "✓ Download completed successfully"
          local result=0
        else
          echo "✗ Download failed after $MAX_RETRIES attempts"
          local result=1
        fi
        
        # Clean up temp cookies
        [[ -n "$temp_cookies" ]] && rm -f "$temp_cookies"
        
        return $result
      }
      
      # YouTube playlist download
      download-youtube-playlist() {
        local url="$*"
        if [[ -z "$url" ]]; then
          echo "Usage: dl-yt-p <playlist-url>"
          return 1
        fi
        
        local cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"
        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local output_template="$DOWNLOAD_DIR/YouTube/%(uploader|)s-%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading YouTube playlist..."
        echo "Output directory: $DOWNLOAD_DIR/YouTube"
        
        local cmd="yt-dlp --yes-playlist"
        [[ -n "$temp_cookies" ]] && cmd="$cmd --cookies '$temp_cookies'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"
        
        if _retry_download "$cmd"; then
          echo "✓ Playlist download completed successfully"
          local result=0
        else
          echo "✗ Playlist download failed after $MAX_RETRIES attempts"
          local result=1
        fi
        
        # Clean up temp cookies
        [[ -n "$temp_cookies" ]] && rm -f "$temp_cookies"
        
        return $result
      }
      
      # Bilibili single video download
      download-bilibili() {
        local url="$*"
        if [[ -z "$url" ]]; then
          echo "Usage: dl-bili <url>"
          return 1
        fi
        
        local cookies_file="$HOME/.config/yt-dlp/cookies-bilibili.txt"
        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local output_template="$DOWNLOAD_DIR/Bilibili/%(uploader|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading Bilibili video..."
        echo "Output directory: $DOWNLOAD_DIR/Bilibili"
        
        local cmd="yt-dlp --referer https://www.bilibili.com/"
        [[ -n "$temp_cookies" ]] && cmd="$cmd --cookies '$temp_cookies'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"
        
        if _retry_download "$cmd"; then
          echo "✓ Download completed successfully"
          local result=0
        else
          echo "✗ Download failed after $MAX_RETRIES attempts"
          local result=1
        fi
        
        # Clean up temp cookies
        [[ -n "$temp_cookies" ]] && rm -f "$temp_cookies"
        
        return $result
      }
      
      # Bilibili playlist/collection download
      download-bilibili-playlist() {
        local url="$*"
        if [[ -z "$url" ]]; then
          echo "Usage: dl-bili-p <playlist-url>"
          return 1
        fi
        
        local cookies_file="$HOME/.config/yt-dlp/cookies-bilibili.txt"
        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local output_template="$DOWNLOAD_DIR/Bilibili/%(uploader|)s-%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading Bilibili playlist..."
        echo "Output directory: $DOWNLOAD_DIR/Bilibili"
        
        local cmd="yt-dlp --yes-playlist --referer https://www.bilibili.com/"
        [[ -n "$temp_cookies" ]] && cmd="$cmd --cookies '$temp_cookies'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"
        
        if _retry_download "$cmd"; then
          echo "✓ Playlist download completed successfully"
          local result=0
        else
          echo "✗ Playlist download failed after $MAX_RETRIES attempts"
          local result=1
        fi
        
        # Clean up temp cookies
        [[ -n "$temp_cookies" ]] && rm -f "$temp_cookies"
        
        return $result
      }
      
      # Function to show help and instructions
      download-help() {
        cat << 'EOF'
      Video Download Commands:
      
      YouTube:
        dl-yt <url>      - Download single YouTube video
        dl-yt-p <url>    - Download YouTube playlist
      
      Bilibili:
        dl-bili <url>    - Download single Bilibili video
        dl-bili-p <url>  - Download Bilibili playlist/collection
      
      Other commands:
        dl-clear-archive - Clear download history (allows re-downloading)
        dl-help          - Show this help message
      
      Cookies Update Instructions:
      
      1. Install a browser extension:
         - Chrome/Edge: "Get cookies.txt LOCALLY"
         - Firefox: "cookies.txt"
      
      2. Log in to the website (youtube.com or bilibili.com)
      
      3. Click the extension and export cookies
      
      4. Save the cookies:
         - YouTube: ~/.config/yt-dlp/cookies-youtube.txt
         - Bilibili: ~/.config/yt-dlp/cookies-bilibili.txt
      
      Alternative method using yt-dlp:
         yt-dlp --cookies-from-browser firefox --cookies cookies-youtube.txt "https://youtube.com"
         yt-dlp --cookies-from-browser firefox --cookies cookies-bilibili.txt "https://bilibili.com"
      EOF
      }
      
      # Function to clear download archive
      dl-clear-archive() {
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
        if [[ -f "$archive_file" ]]; then
          echo "Clearing download archive: $archive_file"
          rm -f "$archive_file"
          echo "✓ Archive cleared. Videos can now be re-downloaded."
        else
          echo "No archive file found at: $archive_file"
        fi
      }
      
      # Alias for backward compatibility
      alias dlv-clear-archive='dl-clear-archive'
      
      # YouTube RSS subscription checker
      check-youtube-subscriptions() {
        ${lib.optionalString cfg.subscriptions.enable ''
        local max_videos="${toString cfg.subscriptions.maxVideosPerFeed}"
        local feeds=(${lib.concatMapStringsSep " " (feed: ''"${feed}"'') cfg.subscriptions.feeds})
        
        if [[ ''${#feeds[@]} -eq 0 ]]; then
          echo "No RSS feeds configured"
          return 0
        fi
        
        echo "Checking ''${#feeds[@]} YouTube subscription feeds..."
        echo "Processing up to $max_videos videos per feed"
        echo ""
        
        for feed in "''${feeds[@]}"; do
          echo "Processing feed: $feed"
          
          # Fetch and parse the RSS feed, extract video links
          local links=$(${pkgs.curl}/bin/curl -s "$feed" | \
            ${pkgs.libxml2}/bin/xmllint --xpath "//*[local-name()='entry']/*[local-name()='link'][@rel='alternate']/@href" - 2>/dev/null | \
            sed 's/href="//g; s/"//g' | \
            head -n "$max_videos")
          
          if [[ -z "$links" ]]; then
            echo "  No videos found or feed unavailable"
            continue
          fi
          
          local count=0
          while IFS= read -r link; do
            if [[ -n "$link" ]]; then
              ((count++))
              echo "  [$count] Downloading: $link"
              download-youtube "$link"
            fi
          done <<< "$links"
          
          echo "  Processed $count videos from this feed"
          echo ""
        done
        
        echo "✓ Subscription check completed"
        ''}
      }
    '';

    # Systemd user service and timer for subscription checking
    systemd.user.services.yt-dlp-subscriptions = mkIf cfg.subscriptions.enable {
      Unit = {
        Description = "Check YouTube RSS subscriptions and download new videos";
        After = [ "network-online.target" ];
      };
      
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "yt-dlp-check-subs" ''
          export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.libxml2}/bin:${pkgs.gnused}/bin:${cfg.package}/bin:$PATH"
          
          # Source the shell init to get our functions
          source ${config.home.homeDirectory}/.zshrc
          
          # Run the subscription check
          check-youtube-subscriptions
        ''}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    systemd.user.timers.yt-dlp-subscriptions = mkIf cfg.subscriptions.enable {
      Unit = {
        Description = "Timer for YouTube subscription checks";
      };
      
      Timer = {
        OnCalendar = cfg.subscriptions.interval;
        Persistent = true;
        RandomizedDelaySec = cfg.subscriptions.randomDelay;
      };
      
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
