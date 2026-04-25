#!/usr/bin/env bash
# Build all host + matching home configs against both the baseline and new
# flake.lock, emit a markdown report at $out_md with per-config closure deltas,
# closure diffs, and per-derivation timings + sizes.
#
# Usage: build-report.sh <system> <host-attr> <baseline-lock> <new-lock> <out-md>
#   system        e.g. x86_64-linux | aarch64-darwin
#   host-attr     e.g. nixosConfigurations | darwinConfigurations
#   baseline-lock path to the pre-update flake.lock
#   new-lock      path to the post-update flake.lock
#   out-md        report destination
set -euo pipefail

system="$1"
host_attr="$2"
baseline_lock="$3"
new_lock="$4"
out_md="$5"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parser="$script_dir/parse-build-times.py"

human_size() {
  awk -v b="$1" 'BEGIN {
    sign = ""
    if (b < 0) { sign = "-"; b = -b }
    s[0]="B"; s[1]="KiB"; s[2]="MiB"; s[3]="GiB"; s[4]="TiB"
    i = 0
    while (b >= 1024 && i < 4) { b /= 1024; i++ }
    printf "%s%.1f %s", sign, b, s[i]
  }'
}

drv_short() {
  basename "$1" | sed -E 's/^[a-z0-9]{32}-//; s/\.drv$//'
}

drv_time() {
  local drv="$1" file="$2"
  awk -v d="$drv" -F'\t' '$1 == d { print $2; exit }' "$file"
}

report_pair() {
  local attr="$1" label="$2"
  echo ">>> $label (baseline)"
  cp "$baseline_lock" flake.lock
  local old_path
  old_path=$(nix build "$attr" --no-link --print-out-paths)

  echo ">>> $label (new)"
  cp "$new_lock" flake.lock
  local build_log start end duration new_path
  build_log=$(mktemp)
  start=$(date +%s)
  new_path=$(nix --log-format internal-json build "$attr" --no-link --print-out-paths \
    2> >(perl -ne 'BEGIN{$|=1} print time," ",$_' > "$build_log"))
  end=$(date +%s)
  duration=$((end - start))

  local times_file
  times_file=$(mktemp)
  python3 "$parser" < "$build_log" > "$times_file" || true

  local old_bytes new_bytes delta
  old_bytes=$(nix path-info -S "$old_path" | awk '{print $NF}')
  new_bytes=$(nix path-info -S "$new_path" | awk '{print $NF}')
  delta=$((new_bytes - old_bytes))

  local old_h new_h delta_h
  old_h=$(human_size "$old_bytes")
  new_h=$(human_size "$new_bytes")
  delta_h=$(human_size "$delta")
  if [ "$delta" -gt 0 ]; then delta_h="+${delta_h}"; fi

  local diff_output diff_total diff_shown
  diff_output=$(nix store diff-closures "$old_path" "$new_path" 2>/dev/null \
    | perl -pe 's/\e\[[0-9;]*m//g' || true)
  if [ -n "$diff_output" ]; then
    diff_total=$(printf '%s\n' "$diff_output" | wc -l | tr -d ' ')
    diff_shown=$(printf '%s\n' "$diff_output" | head -50)
  else
    diff_total=0
    diff_shown=""
  fi

  local built_drvs built_count
  built_drvs=$(awk -F'\t' '{print $1}' "$times_file" 2>/dev/null || true)
  if [ -z "$built_drvs" ]; then
    built_count=0
  else
    built_count=$(printf '%s\n' "$built_drvs" | wc -l | tr -d ' ')
  fi

  {
    echo "#### $label"
    echo ""
    echo "- Wall-clock: ${duration}s"
    echo "- Built derivations: ${built_count}"
    echo "- Closure: ${old_h} → ${new_h} (${delta_h})"
    echo ""

    if [ -n "$diff_shown" ]; then
      local diff_label="Closure diff"
      if [ "$diff_total" -gt 50 ]; then
        diff_label="Closure diff (top 50 of ${diff_total})"
      fi
      echo "<details><summary>${diff_label}</summary>"
      echo ""
      echo '```'
      printf '%s\n' "$diff_shown"
      echo '```'
      echo ""
      echo "</details>"
      echo ""
    fi

    if [ "$built_count" -gt 0 ]; then
      local built_label="Built derivations (${built_count})"
      if [ "$built_count" -gt 30 ]; then
        built_label="Built derivations (top 30 of ${built_count} by build time)"
      fi
      echo "<details><summary>${built_label}</summary>"
      echo ""
      echo "| Derivation | Build time | Output size |"
      echo "|------------|-----------:|------------:|"
      printf '%s\n' "$built_drvs" | head -30 | while IFS= read -r drv; do
        [ -n "$drv" ] || continue
        local out_path sz t short
        out_path=$(nix-store --query --outputs "$drv" 2>/dev/null | head -1 || true)
        if [ -n "$out_path" ] && [ -e "$out_path" ]; then
          sz=$(nix path-info -Sh "$out_path" 2>/dev/null | awk '{print $(NF-1), $NF}' || echo "n/a")
        else
          sz="n/a"
        fi
        t=$(drv_time "$drv" "$times_file")
        short=$(drv_short "$drv")
        echo "| ${short} | ${t:-?}s | ${sz} |"
      done
      echo ""
      echo "</details>"
      echo ""
    fi
  } >> "$out_md"

  rm -f "$build_log" "$times_file"
}

: > "$out_md"
{
  echo "## Build report (${system})"
  echo ""
  echo "### Host configs (${host_attr})"
  echo ""
} >> "$out_md"

for host in $(nix eval ".#${host_attr}" --apply 'x: builtins.attrNames x' --json | jq -r '.[]'); do
  report_pair ".#${host_attr}.${host}.config.system.build.toplevel" "$host"
done

{
  echo "### Home configs (${system})"
  echo ""
} >> "$out_md"

for config in $(nix eval .#homeConfigurations --apply 'x: builtins.attrNames x' --json | jq -r '.[]'); do
  sys=$(nix eval ".#homeConfigurations.\"${config}\".activationPackage.system" --raw 2>/dev/null || true)
  if [ "$sys" = "$system" ]; then
    report_pair ".#homeConfigurations.\"${config}\".activationPackage" "$config"
  fi
done
