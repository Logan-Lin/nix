{ config, pkgs, lib, ... }:

{
  # Rsync exclude patterns for common files and directories
  home.file.".rsync-exclude".text = ''
    # macOS specific
    .DS_Store
    .AppleDouble
    .LSOverride
    Icon?
    ._*
    .DocumentRevisions-V100
    .fseventsd
    .Spotlight-V100
    .TemporaryItems
    .Trashes
    .VolumeIcon.icns
    .com.apple.timemachine.donotpresent
    
    # OS generated files
    Thumbs.db
    ehthumbs.db
    Desktop.ini
    $RECYCLE.BIN/
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

  # Create a convenient rsync wrapper script
  home.file.".local/bin/rsync-backup".text = ''
    #!/bin/bash
    # 
    # Convenient rsync backup wrapper
    # Usage: rsync-backup source/ destination/
    #
    
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <source/> <destination/>"
        echo "Example: $0 ~/Documents/ /backup/documents/"
        exit 1
    fi
    
    SOURCE="$1"
    DEST="$2"
    
    # Ensure source ends with slash for proper rsync behavior
    if [[ "$SOURCE" != */ ]]; then
        SOURCE="$SOURCE/"
    fi
    
    echo "=== Rsync Backup ==="
    echo "Source: $SOURCE"
    echo "Destination: $DEST"
    echo "==================="
    
    # Use the configuration file options
    rsync $(cat ~/.rsync-backup.conf | grep -v '^#' | grep -v '^$' | tr '\n' ' ') "$SOURCE" "$DEST"
    
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully!"
    else
        echo "Backup failed with exit code $?"
        exit 1
    fi
  '';

  # Make the backup script executable
  home.file.".local/bin/rsync-backup".executable = true;

  # Optional: Add rsync aliases to shell configuration
  # This can be integrated with your existing zsh module
  home.file.".rsync-aliases".text = ''
    # Rsync aliases for common operations
    # Source this file in your shell configuration
    
    # Quick backup with progress
    alias rsync-quick='rsync -avh --progress --exclude-from=~/.rsync-exclude'
    
    # Dry run backup (safe testing)
    alias rsync-dry='rsync -avh --progress --exclude-from=~/.rsync-exclude --dry-run'
    
    # Full backup with all safety options
    alias rsync-full='rsync-backup'
    
    # Sync directories (no delete)
    alias rsync-sync='rsync -avh --progress --exclude-from=~/.rsync-exclude'
    
    # Mirror directories (with delete)  
    alias rsync-mirror='rsync -avh --progress --exclude-from=~/.rsync-exclude --delete'
  '';
}
