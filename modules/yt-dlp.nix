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
  };

  config = mkIf cfg.enable {
    # Install yt-dlp, deno, and ffmpeg
    # Deno is required for YouTube downloads (GitHub issue #14404)
    home.packages = with pkgs; [
      cfg.package
      deno     # Required for YouTube downloads due to JS challenges
      ffmpeg
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
      --format "bestvideo[ext=mp4][height<=1080]+bestaudio[ext=m4a]/best[ext=mp4][height<=1080]/best"
      --merge-output-format mp4

      # Download options
      --no-playlist
      --embed-thumbnail
      --write-thumbnail
      --write-description
      --write-info-json

      # Error handling
      --ignore-errors
      --no-abort-on-error

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

    programs.zsh.initContent = ''
      # Base download directory
      DOWNLOAD_DIR="${cfg.downloadDir}"
      DOWNLOAD_DIR="''${DOWNLOAD_DIR/#\~/$HOME}"

      # Retry configuration
      MAX_RETRIES=10
      BASE_DELAY=10

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
      
      # Unified video download function
      dlv() {
        local platform=""
        local playlist_mode=false
        local max_downloads=""
        local custom_retries=""
        local min_duration=""
        local max_duration=""
        local title_filter=""
        local url=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -p|--playlist)
              playlist_mode=true
              shift
              ;;
            -n|--count)
              max_downloads="$2"
              shift 2
              ;;
            -r|--retries)
              custom_retries="$2"
              shift 2
              ;;
            --min)
              min_duration="$2"
              shift 2
              ;;
            --max)
              max_duration="$2"
              shift 2
              ;;
            --title)
              title_filter="$2"
              shift 2
              ;;
            youtube|bilibili)
              platform="$1"
              shift
              ;;
            *)
              url="$url $1"
              shift
              ;;
          esac
        done

        url="''${url## }"  # Trim leading space

        # Validate inputs
        if [[ -z "$platform" ]] || [[ -z "$url" ]]; then
          echo "Usage: dlv <youtube|bilibili> [OPTIONS] <url>"
          echo ""
          echo "Arguments:"
          echo "  youtube|bilibili           Platform to download from"
          echo ""
          echo "Options:"
          echo "  -p, --playlist             Download as playlist"
          echo "  -n, --count <number>       Limit number of videos to process/download"
          echo "  -r, --retries <number>     Number of retry attempts (0 for no retries, default: 10)"
          echo "  --min <minutes>            Minimum video duration in minutes"
          echo "  --max <minutes>            Maximum video duration in minutes"
          echo "  --title <string>           Filter videos by title (case-insensitive)"
          echo ""
          echo "Examples:"
          echo "  dlv youtube <url>                         - Download single YouTube video"
          echo "  dlv youtube -p <url>                      - Download YouTube playlist"
          echo "  dlv youtube --min 5 --max 30 <url>        - Download videos between 5-30 minutes"
          echo "  dlv youtube --title \"tutorial\" <url>      - Download videos with 'tutorial' in title"
          echo "  dlv bilibili -p -n 10 <url>               - Download first 10 videos from playlist"
          return 1
        fi

        # Override MAX_RETRIES if specified
        [[ -n "$custom_retries" ]] && local MAX_RETRIES="$custom_retries"

        # Platform-specific configuration
        local cookies_file platform_name platform_flags
        case "$platform" in
          youtube)
            cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"
            platform_name="YouTube"
            platform_flags=""
            ;;
          bilibili)
            cookies_file="$HOME/.config/yt-dlp/cookies-bilibili.txt"
            platform_name="Bilibili"
            platform_flags="--referer https://www.bilibili.com/"
            ;;
        esac

        # Build match filter (duration and/or title)
        local match_filter=""
        local filter_parts=()

        # Duration filter
        if [[ -n "$min_duration" ]] || [[ -n "$max_duration" ]]; then
          local min_sec=""
          local max_sec=""
          [[ -n "$min_duration" ]] && min_sec=$((min_duration * 60))
          [[ -n "$max_duration" ]] && max_sec=$((max_duration * 60))

          if [[ -n "$min_sec" ]] && [[ -n "$max_sec" ]]; then
            filter_parts+=("duration >= $min_sec & duration <= $max_sec")
          elif [[ -n "$min_sec" ]]; then
            filter_parts+=("duration >= $min_sec")
          elif [[ -n "$max_sec" ]]; then
            filter_parts+=("duration <= $max_sec")
          fi
        fi

        # Title filter
        if [[ -n "$title_filter" ]]; then
          filter_parts+=("title ~= '(?i).*$title_filter.*'")
        fi

        # Combine filters
        if [[ ''${#filter_parts[@]} -gt 0 ]]; then
          local combined_filter
          combined_filter=$(IFS=" & "; echo "''${filter_parts[*]}")
          match_filter="--match-filter \"$combined_filter\""
        fi

        # Build output template based on playlist mode
        local output_template
        if [[ "$playlist_mode" == true ]]; then
          output_template="$DOWNLOAD_DIR/$platform_name/%(uploader|)s-%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
        else
          output_template="$DOWNLOAD_DIR/$platform_name/%(uploader|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        fi

        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local archive_file="$DOWNLOAD_DIR/.archive.txt"

        # Setup and display info
        mkdir -p "$DOWNLOAD_DIR"
        if [[ "$playlist_mode" == true ]]; then
          echo "Downloading $platform_name playlist..."
          [[ -n "$max_downloads" ]] && echo "Limiting to $max_downloads videos"
        else
          echo "Downloading $platform_name video..."
          [[ -n "$max_downloads" ]] && echo "Processing max $max_downloads videos"
        fi
        echo "Output directory: $DOWNLOAD_DIR/$platform_name"

        # Build command
        local cmd="yt-dlp $platform_flags $match_filter"
        if [[ "$playlist_mode" == true ]]; then
          cmd="$cmd --yes-playlist"
        fi
        [[ -n "$max_downloads" ]] && cmd="$cmd --playlist-end '$max_downloads'"
        [[ -n "$temp_cookies" ]] && cmd="$cmd --cookies '$temp_cookies'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"

        # Execute download with retry
        if _retry_download "$cmd"; then
          # Build success message
          local success_msg="$platform_name download completed"
          [[ "$playlist_mode" == true ]] && success_msg="$platform_name playlist download completed"

          # Add filter info if any
          local filter_info=""
          if [[ -n "$min_duration" ]] || [[ -n "$max_duration" ]] || [[ -n "$title_filter" ]]; then
            filter_info=" (Filters:"
            [[ -n "$min_duration" ]] && filter_info="$filter_info min ''${min_duration}m"
            [[ -n "$max_duration" ]] && filter_info="$filter_info max ''${max_duration}m"
            [[ -n "$title_filter" ]] && filter_info="$filter_info title: \"$title_filter\""
            filter_info="$filter_info)"
          fi
          [[ -n "$max_downloads" ]] && filter_info="''${filter_info} [max ''${max_downloads} videos]"

          success_msg="''${success_msg}''${filter_info}: $url"

          if [[ "$playlist_mode" == true ]]; then
            echo "✓ Playlist download completed successfully"
          else
            echo "✓ Download completed successfully"
          fi

          local result=0
        else
          # Build failure message
          local fail_msg="$platform_name download failed after $MAX_RETRIES attempts"
          [[ "$playlist_mode" == true ]] && fail_msg="$platform_name playlist download failed after $MAX_RETRIES attempts"
          fail_msg="''${fail_msg}: $url"

          if [[ "$playlist_mode" == true ]]; then
            echo "✗ Playlist download failed after $MAX_RETRIES attempts"
          else
            echo "✗ Download failed after $MAX_RETRIES attempts"
          fi

          local result=1
        fi

        # Clean up temp cookies
        [[ -n "$temp_cookies" ]] && rm -f "$temp_cookies"

        return $result
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
    '';
  };
}
