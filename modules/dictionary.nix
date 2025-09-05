{ pkgs, ... }:

let
  # Create dictionary setup script that downloads and extracts dictionaries
  setupDictionaries = pkgs.writeShellScript "setup-dictionaries" ''
    # Create dictionary directory
    mkdir -p "$HOME/.stardict/dic"
    
    # Function to download and extract dictionary
    download_dict() {
      local url="$1"
      local filename="$2"
      local extract_dir="$HOME/.stardict/dic"
      
      if [ ! -f "$extract_dir/.$(basename $filename)-extracted" ]; then
        echo "Downloading $filename..."
        if ${pkgs.curl}/bin/curl -L -o "/tmp/$filename" "$url"; then
          echo "Extracting $filename..."
          ${pkgs.gnutar}/bin/tar -xf "/tmp/$filename" -C "$extract_dir" --strip-components=1 2>/dev/null || \
          ${pkgs.gnutar}/bin/tar -xf "/tmp/$filename" -C "$extract_dir" 2>/dev/null || true
          
          # Clean up
          rm -f "/tmp/$filename"
          touch "$extract_dir/.$(basename $filename)-extracted"
          echo "$filename setup complete!"
        else
          echo "Failed to download $filename"
        fi
      fi
    }
    
    # Download dictionaries (using working URLs)
    download_dict "https://web.archive.org/web/20200702203642/http://download.huzheng.org/dict.org/stardict-dictd_www.dict.org_gcide-2.4.2.tar.bz2" "gcide-dict.tar.bz2"
    download_dict "https://cyphar.github.io/jpn-stardicts/JMdict-ja-en.tar.gz" "jmdict-ja-en.tar.gz"
    
    echo "Dictionary setup process completed!"
  '';

in
{
  home.packages = with pkgs; [
    sdcv
    curl       # For downloading dictionaries
    gnutar     # For extracting dictionaries
  ];

  # Environment variable for dictionary location
  home.sessionVariables = {
    STARDICT_DATA_DIR = "$HOME/.stardict/dic";
  };

  # Note: Dictionary files will be downloaded automatically when you first run 'dict-setup'
  # or you can run the setup manually at any time

  # Shell aliases for different dictionary types
  programs.zsh.shellAliases = {
    # English-English dictionary
    "def" = "sdcv";
    "define" = "sdcv";

    # Japanese-English dictionary
    "j2e" = "sdcv -u JMdict-ja-en";
    
    # English-Japanese dictionary (same as Japanese-English - JMdict is bidirectional)
    "e2j" = "sdcv -u JMdict-ja-en";
    
    # List available dictionaries
    "dict-list" = "sdcv -l";
    
    # Manual dictionary setup
    "dict-setup" = toString setupDictionaries;
    
    # Disable auto-setup for future activations
    "dict-disable-auto-setup" = "touch $HOME/.stardict/.skip-auto-setup";
  };
}
