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
    # Install yt-dlp and ffmpeg
    home.packages = with pkgs; [
      cfg.package
      ffmpeg
    ];

    # Copy cookie files (not symlink) to make them writable
    home.file.".config/yt-dlp/cookies-youtube.txt" = {
      source = ../config/yt-dlp/cookies-youtube.txt;
      onChange = ''
        chmod 644 ~/.config/yt-dlp/cookies-youtube.txt
      '';
    };
    home.file.".config/yt-dlp/cookies-bilibili.txt" = {
      source = ../config/yt-dlp/cookies-bilibili.txt;
      onChange = ''
        chmod 644 ~/.config/yt-dlp/cookies-bilibili.txt
      '';
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
      --embed-subs
      --sub-langs "en,zh-CN,zh-TW"
      --write-auto-subs
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

    # Shell alias and function
    programs.zsh.shellAliases = {
      # Simple alias that calls the function
      dlv = "download-video";
    };

    programs.zsh.initContent = ''
      # Function to download videos from YouTube or Bilibili
      download-video() {
        local url="$1"
        local download_dir="${cfg.downloadDir}"
        
        if [[ -z "$url" ]]; then
          echo "Usage: dlv <url>"
          echo "Downloads video from YouTube or Bilibili"
          return 1
        fi
        
        # Expand tilde in download directory
        download_dir="''${download_dir/#\~/$HOME}"
        
        # Detect platform from URL
        local platform=""
        local cookies_file=""
        local extra_args=""
        
        if [[ "$url" =~ (youtube\.com|youtu\.be) ]]; then
          platform="YouTube"
          cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"
          # YouTube-specific output template - use channel as fallback for uploader
          local output_template="$download_dir/YouTube/%(uploader|)s%(channel|)s%(uploader_id|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        elif [[ "$url" =~ bilibili\.com ]]; then
          platform="Bilibili"
          cookies_file="$HOME/.config/yt-dlp/cookies-bilibili.txt"
          # Bilibili-specific arguments
          extra_args="--referer https://www.bilibili.com/"
          # Bilibili-specific output template - use owner as uploader for Bilibili
          local output_template="$download_dir/Bilibili/%(uploader|)s%(channel|)s%(uploader_id|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        else
          echo "Warning: Unknown platform, proceeding without cookies"
          platform="Unknown"
          local output_template="$download_dir/%(uploader|)s%(channel|)s%(uploader_id|)s/%(upload_date>%Y%m%d|)s-%(title)s.%(ext)s"
        fi
        
        # Check if it's a playlist
        if [[ "$url" =~ "list=" ]] || [[ "$url" =~ "/playlist" ]] || [[ "$url" =~ "bilibili\.com/.*/channel" ]] || [[ "$url" =~ "bilibili\.com/.*/collectiondetail" ]]; then
          echo "Detected playlist URL"
          # For playlists, use different output template
          if [[ "$platform" == "YouTube" ]]; then
            output_template="$download_dir/YouTube/%(playlist_title|)s%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
          elif [[ "$platform" == "Bilibili" ]]; then
            output_template="$download_dir/Bilibili/%(playlist_title|)s%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
          else
            output_template="$download_dir/%(playlist_title|)s%(playlist|)s/%(playlist_index|)03d-%(title)s.%(ext)s"
          fi
          extra_args="$extra_args --yes-playlist"
        fi
        
        echo "Downloading from $platform..."
        echo "Output directory: $download_dir"
        
        # Build yt-dlp command
        local cmd="yt-dlp"
        
        # Add cookies if file exists - copy to temp file to avoid permission issues
        if [[ -f "$cookies_file" ]]; then
          echo "Using cookies from: $cookies_file"
          # Create a temporary writable copy of the cookie file
          local temp_cookies="/tmp/yt-dlp-cookies-$$.txt"
          cp "$cookies_file" "$temp_cookies"
          chmod 644 "$temp_cookies"
          cmd="$cmd --cookies \"$temp_cookies\""
          # Clean up temp file after download
          trap "rm -f $temp_cookies" EXIT
        fi
        
        # Add archive file to track downloads
        local archive_file="$download_dir/.archive.txt"
        cmd="$cmd --download-archive \"$archive_file\""
        
        # Add output template and extra arguments
        cmd="$cmd -o \"$output_template\" $extra_args \"$url\""
        
        # Create download directory if it doesn't exist
        mkdir -p "$download_dir"
        
        # Execute the command
        eval $cmd
        
        if [[ $? -eq 0 ]]; then
          echo "✓ Download completed successfully"
        else
          echo "✗ Download failed"
          return 1
        fi
      }
      
      # Function to show instructions for updating cookies
      update-cookies-instructions() {
        cat << 'EOF'
      To update cookies for YouTube or Bilibili:
      
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
      
      alias dlv-help='update-cookies-instructions'
      
      # Function to clear download archive
      dlv-clear-archive() {
        local download_dir="${cfg.downloadDir}"
        download_dir="''${download_dir/#\~/$HOME}"
        local archive_file="$download_dir/.archive.txt"
        
        if [[ -f "$archive_file" ]]; then
          echo "Clearing download archive: $archive_file"
          rm -f "$archive_file"
          echo "✓ Archive cleared. Videos can now be re-downloaded."
        else
          echo "No archive file found at: $archive_file"
        fi
      }
    '';
  };
}
