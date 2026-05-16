# NOTE: cookie file at `~/.config/yt-dlp/cookies-youtube.txt`

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.yt-dlp-custom;
in

{
  options.programs.yt-dlp-custom = {
    enable = mkEnableOption "yt-dlp youtube audio downloader configuration";

    downloadDir = mkOption {
      type = types.str;
      description = "Base directory for downloaded audio";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      yt-dlp
      deno
      ffmpeg
      python312Packages.bgutil-ytdlp-pot-provider
    ];

    home.file.".config/yt-dlp/config".text = ''
      --format "bestaudio[ext=m4a]/bestaudio/best"
      --extract-audio
      --audio-format m4a
      --embed-metadata
      --parse-metadata "%(uploader)s:%(meta_album)s"
      --parse-metadata "%(uploader)s:%(meta_album_artist)s"
      --no-playlist
      --embed-thumbnail
      --no-embed-chapters
      --ignore-errors
      --no-abort-on-error
      --concurrent-fragments 4
      --retries 10
      --fragment-retries 10
      --sponsorblock-mark all
      --remote-components ejs:npm
      --extractor-args "youtube:formats=missing_pot"
      --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    '';

    programs.zsh.initContent = ''
      DOWNLOAD_DIR="${cfg.downloadDir}"
      DOWNLOAD_DIR="''${DOWNLOAD_DIR/#\~/$HOME}"

      dlv() {
        local max_downloads=""
        local min_duration=""
        local max_duration=""
        local days_filter=""
        local custom_download_dir=""
        local url=""

        while [[ $# -gt 0 ]]; do
          case "$1" in
            -d|--dir)
              custom_download_dir="$2"
              shift 2
              ;;
            -n|--count)
              max_downloads="$2"
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
            --days|--within-days)
              days_filter="$2"
              shift 2
              ;;
            *)
              url="$url $1"
              shift
              ;;
          esac
        done

        url="''${url## }"

        if [[ -z "$url" ]]; then
          echo "Usage: dlv [OPTIONS] <url>"
          echo ""
          echo "Options:"
          echo "  -d, --dir <path>           Override download directory"
          echo "  -n, --count <number>       Limit number of videos to process/download"
          echo "  --min <minutes>            Minimum duration in minutes"
          echo "  --max <minutes>            Maximum duration in minutes"
          echo "  --days <number>            Download videos uploaded within N days"
          echo ""
          echo "Examples:"
          echo "  dlv <url>                          - Download single YouTube video"
          echo "  dlv --min 5 --max 30 <url>         - Download videos between 5-30 minutes"
          echo "  dlv --days 7 <url>                 - Download videos from last 7 days"
          echo "  dlv -n 10 <url>                    - Download first 10 videos"
          echo "  dlv -d /mnt/media <url>            - Download to custom directory"
          return 1
        fi

        local DOWNLOAD_DIR="$DOWNLOAD_DIR"
        if [[ -n "$custom_download_dir" ]]; then
          DOWNLOAD_DIR="''${custom_download_dir/#\~/$HOME}"
        fi

        local cookies_file="$HOME/.config/yt-dlp/cookies-youtube.txt"

        local match_filter=""
        local filter_parts=()

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

        if [[ ''${#filter_parts[@]} -gt 0 ]]; then
          local combined_filter
          combined_filter=$(IFS=" & "; echo "''${filter_parts[*]}")
          match_filter="--match-filter \"$combined_filter\""
        fi

        local output_template="$DOWNLOAD_DIR/youtube/%(uploader|Unknown)s/%(title)s.%(ext)s"

        mkdir -p "$DOWNLOAD_DIR"

        local cmd="yt-dlp $match_filter --no-write-playlist-metafiles"
        [[ -n "$max_downloads" ]] && cmd="$cmd --playlist-end '$max_downloads'"
        [[ -n "$days_filter" ]] && cmd="$cmd --dateafter 'today-''${days_filter}days'"
        [[ -f "$cookies_file" ]] && cmd="$cmd --cookies '$cookies_file'" || cmd="$cmd --no-cookies"
        cmd="$cmd -o '$output_template' '$url'"

        eval "$cmd"
      }
    '';
  };
}
