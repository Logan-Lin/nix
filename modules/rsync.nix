{ config, pkgs, lib, ... }:

{
  # Install rsync package
  home.packages = with pkgs; [ rsync exiftool ];

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

      rsync -avh --progress --delete --partial --partial-dir=.rsync-partial --compress "$SOURCE" "$DEST"

      if [[ $? -eq 0 ]]; then
        echo "Backup completed successfully!"
      else
        echo "Backup failed with exit code $?"
        return 1
      fi
    }
  '';

  programs.zsh.shellAliases = {
    rsync-quick = "rsync -avh --progress";
    rsync-dry = "rsync -avh --progress --dry-run";
    rsync-full = "rsync-backup";
    rsync-sync = "rsync -avh --progress";
    rsync-mirror = "rsync -avh --progress --delete";
  };
}
