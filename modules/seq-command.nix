{ pkgs, ... }:

let
  seqCommandScript = pkgs.writeShellScriptBin "seq-command" ''
    gap=0
    file=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --gap)
          gap="$2"
          shift 2
          ;;
        *)
          file="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$file" || "$gap" -eq 0 ]]; then
      echo "seq-command - Execute commands from a file sequentially with gaps"
      echo ""
      echo "Usage: seq-command --gap <minutes> <commands-file>"
      echo ""
      echo "Options:"
      echo "  --gap <minutes>  Wait time between command executions"
      echo ""
      echo "The commands file is treated as a FIFO queue - each line is removed after execution."
      exit 1
    fi

    file="$(realpath "$file")"

    if [[ ! -f "$file" ]]; then
      echo "File not found: $file"
      exit 1
    fi

    gap_seconds=$((gap * 60))

    while [[ -s "$file" ]]; do
      cmd="$(head -n 1 "$file")"
      tail -n +2 "$file" > "$file.tmp" && mv "$file.tmp" "$file"

      if [[ -n "$cmd" ]]; then
        eval "$cmd"
      fi

      if [[ -s "$file" ]]; then
        sleep "$gap_seconds"
      fi
    done
  '';
in
{
  home.packages = [ seqCommandScript ];
}
