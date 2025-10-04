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
      --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
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
    };

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
      
      # YouTube single video download
      download-youtube() {
        local max_downloads=""
        local url=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -n|--max)
              max_downloads="$2"
              shift 2
              ;;
            *)
              url="$url $1"
              shift
              ;;
          esac
        done

        url="''${url## }"  # Trim leading space

        if [[ -z "$url" ]]; then
          echo "Usage: dl-yt [-n|--max <number>] <url>"
          echo "  -n, --max <number>  Limit number of videos to process (useful for channels/playlists)"
          return 1
        fi

        local cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"
        local temp_cookies=$(_setup_temp_cookies "$cookies_file")
        local output_template="$DOWNLOAD_DIR/YouTube/%(uploader|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        local archive_file="$DOWNLOAD_DIR/.archive.txt"

        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading YouTube video..."
        [[ -n "$max_downloads" ]] && echo "Processing max $max_downloads videos"
        echo "Output directory: $DOWNLOAD_DIR/YouTube"

        local cmd="yt-dlp --match-filter 'duration >? 60'"
        [[ -n "$max_downloads" ]] && cmd="$cmd --playlist-end '$max_downloads'"
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
    '';
  };
}
