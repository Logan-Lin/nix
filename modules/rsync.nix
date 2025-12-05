{ config, pkgs, lib, ... }:

{
  # Install rsync package
  home.packages = with pkgs; [ rsync exiftool ];
  # Rsync exclude patterns for common files and directories
  home.file.".rsync-exclude".text = ''
  '';

  # Rsync configuration for common backup scenarios
  home.file.".rsync-backup.conf".text = ''
    # Common rsync options for backups
    # Usage: rsync @backup-options source/ destination/
    
    # Standard backup options
    --archive
    --verbose
    --progress
    --human-readable
    --exclude-from=~/.rsync-exclude
    --delete
    --delete-excluded
    --partial
    --partial-dir=.rsync-partial

    ${lib.optionalString pkgs.stdenv.isDarwin ''
      # Preserve extended attributes and ACLs (macOS)
      --extended-attributes
      --acls
    ''}

    # Network optimization
    --compress
    --compress-level=6
    
    # Safety options
    --dry-run  # Remove this line when you're ready to run for real
  '';

  programs.zsh.initContent = ''
    function rsync-backup() {
      if [[ $# -ne 2 ]]; then
        echo "Usage: rsync-backup <source/> <destination/>"
        echo "Example: rsync-backup ~/Documents/ /backup/documents/"
        return 1
      fi

      local SOURCE="$1"
      local DEST="$2"

      if [[ "$SOURCE" != */ ]]; then
        SOURCE="$SOURCE/"
      fi

      echo "=== Rsync Backup ==="
      echo "Source: $SOURCE"
      echo "Destination: $DEST"
      echo "==================="

      rsync $(cat ~/.rsync-backup.conf | grep -v '^#' | grep -v '^$' | tr '\n' ' ') "$SOURCE" "$DEST"

      if [[ $? -eq 0 ]]; then
        echo "Backup completed successfully!"
      else
        echo "Backup failed with exit code $?"
        return 1
      fi
    }

    function camera-copy() {
      if [[ $# -ne 2 ]]; then
        echo "Usage: camera-copy <source_dir> <destination>"
        echo ""
        echo "Copy video files organized by date (YYYY-MM-DD/filename)"
        echo ""
        echo "Examples:"
        echo "  camera-copy /media/sdcard/DCIM ~/Videos/imports"
        echo "  camera-copy /Volumes/CAMERA/DCIM user@nas:/backup/camera"
        return 1
      fi

      local SOURCE="$1"
      local DEST="$2"

      if [[ ! -d "$SOURCE" ]]; then
        echo "Error: Source directory does not exist: $SOURCE"
        return 1
      fi

      _get_video_date() {
        local file="$1"
        local raw_date

        raw_date=$(${pkgs.exiftool}/bin/exiftool -s3 -d '%Y-%m-%d' \
          -DateTimeOriginal -CreateDate -MediaCreateDate "$file" 2>/dev/null | head -1)

        if [[ -n "$raw_date" && "$raw_date" != "0000-00-00" ]]; then
          echo "$raw_date"
        else
          local mtime
          mtime=$(${pkgs.coreutils}/bin/stat -c '%Y' "$file" 2>/dev/null)
          ${pkgs.coreutils}/bin/date -d "@$mtime" +%Y-%m-%d
        fi
      }

      local copied=0
      local failed=0

      while IFS= read -r -d "" file; do
        local date_dir=$(_get_video_date "$file")
        local year=''${date_dir:0:4}
        local filename=$(basename "$file")

        echo "[$date_dir] $filename"

        if ${pkgs.rsync}/bin/rsync -a --mkpath --progress --partial --ignore-existing \
            "$file" "$DEST/$year/$date_dir/$filename"; then
          ((copied++)) || true
        else
          echo "  Failed to copy: $file"
          ((failed++)) || true
        fi
      done < <(find "$SOURCE" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mts" -o -iname "*.m2ts" -o -iname "*.avi" \) -print0)

      echo ""
      echo "=== Summary ==="
      echo "Copied: $copied"
      echo "Failed: $failed"
    }
  '';

  programs.zsh.shellAliases = {
    rsync-quick = "rsync -avh --progress --exclude-from=~/.rsync-exclude";
    rsync-dry = "rsync -avh --progress --exclude-from=~/.rsync-exclude --dry-run";
    rsync-full = "rsync-backup";
    rsync-sync = "rsync -avh --progress --exclude-from=~/.rsync-exclude";
    rsync-mirror = "rsync -avh --progress --exclude-from=~/.rsync-exclude --delete";
  };
}
