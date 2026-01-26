# NOTE: Cookie files at:
#   ~/.config/yt-dlp/cookies-youtube.txt
#   ~/.config/yt-dlp/cookies-bilibili.txt

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
      jq       # For JSON parsing in cleanup functions
      python312Packages.bgutil-ytdlp-pot-provider  # PO token provider for YouTube
    ];

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

      # Remote components for JavaScript challenge solving (required for YouTube)
      --remote-components ejs:npm

      # Extractor arguments for format handling
      --extractor-args "youtube:formats=missing_pot"

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
      
      # Generate Jellyfin-compatible NFO files from yt-dlp metadata
      _generate_jellyfin_nfo() {
        local filepath="$1"
        [[ -z "$filepath" ]] && return 1

        local dir=$(dirname "$filepath")
        local basename=$(basename "$filepath")
        local name_noext="''${basename%.*}"
        local season_dir="$dir"
        local series_dir=$(dirname "$season_dir")
        local json_file="$dir/$name_noext.info.json"

        [[ ! -f "$json_file" ]] && return 1

        local title=$(jq -r '.title // "Unknown"' "$json_file")
        local description=$(jq -r '.description // ""' "$json_file" | head -c 2000)
        local upload_date=$(jq -r '.upload_date // ""' "$json_file")
        local uploader=$(jq -r '.uploader // "Unknown"' "$json_file")

        local season_num=""
        local episode_num=""
        local aired_date=""
        if [[ ''${#upload_date} -eq 8 ]]; then
          season_num="''${upload_date:0:4}"
          episode_num="''${upload_date:4:4}"
          aired_date="''${upload_date:0:4}-''${upload_date:4:2}-''${upload_date:6:2}"
        fi

        description=$(echo "$description" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        title=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        uploader=$(echo "$uploader" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

        local nfo_file="$dir/$name_noext.nfo"
        cat > "$nfo_file" << EPISODENFO
<?xml version="1.0" encoding="UTF-8"?>
<episodedetails>
  <title>$title</title>
  <season>$season_num</season>
  <episode>$episode_num</episode>
  <aired>''${aired_date:-}</aired>
  <plot>$description</plot>
</episodedetails>
EPISODENFO

        if [[ ! -f "$series_dir/tvshow.nfo" ]]; then
          cat > "$series_dir/tvshow.nfo" << TVSHOWNFO
<?xml version="1.0" encoding="UTF-8"?>
<tvshow>
  <title>$uploader</title>
  <plot>Videos from $uploader</plot>
</tvshow>
TVSHOWNFO
        fi

        if [[ ! -f "$season_dir/season.nfo" ]] && [[ -n "$season_num" ]]; then
          cat > "$season_dir/season.nfo" << SEASONNFO
<?xml version="1.0" encoding="UTF-8"?>
<season>
  <title>Season $season_num</title>
  <seasonnumber>$season_num</seasonnumber>
</season>
SEASONNFO
        fi

        local thumb_file=""
        for ext in jpg webp png; do
          if [[ -f "$dir/$name_noext.$ext" ]]; then
            thumb_file="$dir/$name_noext.$ext"
            break
          fi
        done

        if [[ -n "$thumb_file" ]]; then
          local thumb_ext="''${thumb_file##*.}"
          mv "$thumb_file" "$dir/$name_noext-thumb.$thumb_ext" 2>/dev/null

          if [[ ! -f "$series_dir/poster.jpg" ]] && [[ ! -f "$series_dir/poster.webp" ]] && [[ ! -f "$series_dir/poster.png" ]]; then
            cp "$dir/$name_noext-thumb.$thumb_ext" "$series_dir/poster.$thumb_ext"
          fi

          if [[ ! -f "$season_dir/poster.jpg" ]] && [[ ! -f "$season_dir/poster.webp" ]] && [[ ! -f "$season_dir/poster.png" ]]; then
            cp "$dir/$name_noext-thumb.$thumb_ext" "$season_dir/poster.$thumb_ext"
          fi
        fi
      }

      # Unified video download function
      dlv() {
        local platform=""
        local max_downloads=""
        local custom_retries=""
        local min_duration=""
        local max_duration=""
        local title_filter=""
        local days_filter=""
        local audio_only=false
        local max_resolution=""
        local url=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
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
            --days|--within-days)
              days_filter="$2"
              shift 2
              ;;
            -a|--audio)
              audio_only=true
              shift
              ;;
            --res|--resolution)
              max_resolution="$2"
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
          echo "  -n, --count <number>       Limit number of videos to process/download"
          echo "  -r, --retries <number>     Number of retry attempts (0 for no retries, default: 10)"
          echo "  --min <minutes>            Minimum video duration in minutes"
          echo "  --max <minutes>            Maximum video duration in minutes"
          echo "  --title <string>           Filter videos by title (case-insensitive)"
          echo "  --days <number>            Download videos uploaded within N days"
          echo "  -a, --audio                Download audio only (no video)"
          echo "  --res <resolution>         Max video resolution (e.g., 720, 1080, 2160)"
          echo ""
          echo "Examples:"
          echo "  dlv youtube <url>                         - Download single YouTube video"
          echo "  dlv youtube --min 5 --max 30 <url>        - Download videos between 5-30 minutes"
          echo "  dlv youtube --title \"tutorial\" <url>      - Download videos with 'tutorial' in title"
          echo "  dlv youtube --days 7 <url>                - Download videos from last 7 days"
          echo "  dlv bilibili -n 10 <url>                  - Download first 10 videos"
          echo "  dlv youtube -a <url>                      - Download audio only"
          echo "  dlv youtube --res 720 <url>               - Download max 720p video"
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

        # Build output template (Jellyfin TV show format)
        local output_template="$DOWNLOAD_DIR/$platform_name/%(uploader|Unknown)s/Season %(upload_date>%Y|0000)s/S%(upload_date>%Y|0000)sE%(upload_date>%m%d|0000)s - %(title)s.%(ext)s"

        local archive_file="$DOWNLOAD_DIR/.archive.txt"

        # Setup and display info
        mkdir -p "$DOWNLOAD_DIR"
        echo "Downloading $platform_name video..."
        [[ -n "$max_downloads" ]] && echo "Processing max $max_downloads videos"
        echo "Output directory: $DOWNLOAD_DIR/$platform_name"

        # Build format string for audio-only or resolution limit
        local format_string=""
        if [[ "$audio_only" == true ]]; then
          format_string="--format 'bestaudio[ext=m4a]/bestaudio/best' --extract-audio --audio-format m4a"
        elif [[ -n "$max_resolution" ]]; then
          format_string="--format 'bestvideo[ext=mp4][height<=$max_resolution]+bestaudio[ext=m4a]/best[ext=mp4][height<=$max_resolution]/best'"
        fi

        # Build command
        local cmd="yt-dlp $platform_flags $format_string $match_filter --no-write-playlist-metafiles"
        [[ -n "$max_downloads" ]] && cmd="$cmd --playlist-end '$max_downloads'"
        [[ -n "$days_filter" ]] && cmd="$cmd --dateafter 'today-''${days_filter}days'"
        [[ -f "$cookies_file" ]] && cmd="$cmd --cookies '$cookies_file'" || cmd="$cmd --no-cookies"
        cmd="$cmd --download-archive '$archive_file' -o '$output_template' '$url'"

        # Execute download with retry
        if _retry_download "$cmd"; then
          # Generate NFO files for any videos missing them
          local series_base="$DOWNLOAD_DIR/$platform_name"
          find "$series_base" -name "*.info.json" 2>/dev/null | while read -r json_file; do
            local base="''${json_file%.info.json}"
            local nfo_file="$base.nfo"
            if [[ ! -f "$nfo_file" ]]; then
              for ext in mp4 mkv webm m4a mp3 wav flac; do
                [[ -f "$base.$ext" ]] && _generate_jellyfin_nfo "$base.$ext" && break
              done
            fi
          done

          # Build success message
          local success_msg="$platform_name download completed"

          # Add filter info if any
          local filter_info=""
          if [[ -n "$min_duration" ]] || [[ -n "$max_duration" ]] || [[ -n "$title_filter" ]] || [[ -n "$days_filter" ]] || [[ "$audio_only" == true ]] || [[ -n "$max_resolution" ]]; then
            filter_info=" (Filters:"
            [[ "$audio_only" == true ]] && filter_info="$filter_info audio-only"
            [[ -n "$max_resolution" ]] && filter_info="$filter_info max ''${max_resolution}p"
            [[ -n "$min_duration" ]] && filter_info="$filter_info min ''${min_duration}m"
            [[ -n "$max_duration" ]] && filter_info="$filter_info max ''${max_duration}m"
            [[ -n "$title_filter" ]] && filter_info="$filter_info title: \"$title_filter\""
            [[ -n "$days_filter" ]] && filter_info="$filter_info within ''${days_filter} days"
            filter_info="$filter_info)"
          fi
          [[ -n "$max_downloads" ]] && filter_info="''${filter_info} [max ''${max_downloads} videos]"

          success_msg="''${success_msg}''${filter_info}: $url"

          echo "✓ Download completed successfully"

          local result=0
        else
          # Build failure message
          local fail_msg="$platform_name download failed after $MAX_RETRIES attempts: $url"

          echo "✗ Download failed after $MAX_RETRIES attempts"

          local result=1
        fi

        return $result
      }
      
      # Function to clear download archive
      dlv-clear-archive() {
        local archive_file="$DOWNLOAD_DIR/.archive.txt"
        
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
