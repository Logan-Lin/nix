#!/usr/bin/env bash
# Build all host + matching home configs against the current flake.lock, emit a
# markdown report at $out_md with system-level top 20 derivations by build time
# and by output size (separately for hosts and home configs), per-config
# wall-clock / closure size summary, and a system-level diagnostics section.
#
# Usage: build-report.sh <system> <host-attr> <out-md>
#   system     e.g. x86_64-linux | aarch64-darwin
#   host-attr  e.g. nixosConfigurations | darwinConfigurations
#   out-md     report destination
set -euo pipefail

system="$1"
host_attr="$2"
out_md="$3"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parser="$script_dir/parse-build-times.py"
warner="$script_dir/extract-warnings.py"

warnings_file=$(mktemp)
host_agg=$(mktemp)
home_agg=$(mktemp)
per_config_md=$(mktemp)
trap 'rm -f "$warnings_file" "$host_agg" "$home_agg" "$per_config_md"' EXIT

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

report_one() {
  local attr="$1" label="$2" agg_file="$3"
  echo ">>> $label"

  local build_log times_file size_file
  build_log=$(mktemp)
  times_file=$(mktemp)
  size_file=$(mktemp)

  local start end duration out_path
  start=$(date +%s)
  out_path=$(nix --log-format internal-json build "$attr" --no-link --print-out-paths \
    2> >(perl -ne 'BEGIN{$|=1} print time," ",$_' > "$build_log"))
  end=$(date +%s)
  duration=$((end - start))

  python3 "$parser" < "$build_log" > "$times_file" || true
  python3 "$warner" < "$build_log" >> "$warnings_file" || true

  local closure_bytes closure_h built_count
  closure_bytes=$(nix path-info -S "$out_path" | awk '{print $NF}')
  closure_h=$(human_size "$closure_bytes")
  if [ -s "$times_file" ]; then
    built_count=$(wc -l < "$times_file" | tr -d ' ')
  else
    built_count=0
  fi

  while IFS=$'\t' read -r drv secs; do
    [ -n "$drv" ] || continue
    local out_p sz
    out_p=$(nix-store --query --outputs "$drv" 2>/dev/null | head -1 || true)
    if [ -n "$out_p" ] && [ -e "$out_p" ]; then
      sz=$(nix path-info -s "$out_p" 2>/dev/null | awk '{print $NF}')
    else
      sz=0
    fi
    printf '%s\t%s\t%s\t%s\n' "$drv" "$secs" "$sz" "$(drv_short "$drv")"
  done < "$times_file" > "$size_file"

  cat "$size_file" >> "$agg_file"

  {
    echo "#### $label"
    echo ""
    echo "- Wall-clock: ${duration}s"
    echo "- Built derivations: ${built_count}"
    echo "- Closure: ${closure_h}"
    echo ""
  } >> "$per_config_md"

  rm -f "$build_log" "$times_file" "$size_file"
}

emit_top20() {
  local agg="$1" title="$2" mode="$3"
  echo "### $title"
  echo ""
  if [ -s "$agg" ]; then
    if [ "$mode" = "time" ]; then
      echo "| Derivation | Build time | Output size |"
      echo "|------------|-----------:|------------:|"
      sort -t$'\t' -k2,2 -n -r "$agg" | awk 'NR<=20' | while IFS=$'\t' read -r _drv secs bytes short; do
        printf '| %s | %ss | %s |\n' "$short" "$secs" "$(human_size "$bytes")"
      done
    else
      echo "| Derivation | Output size | Build time |"
      echo "|------------|------------:|-----------:|"
      sort -t$'\t' -k3,3 -n -r "$agg" | awk 'NR<=20' | while IFS=$'\t' read -r _drv secs bytes short; do
        printf '| %s | %s | %ss |\n' "$short" "$(human_size "$bytes")" "$secs"
      done
    fi
    echo ""
  fi
}

: > "$out_md"
echo "## Build report (${system})" >> "$out_md"
echo "" >> "$out_md"

{
  echo "### Host configs (${host_attr})"
  echo ""
} >> "$per_config_md"
for host in $(nix eval ".#${host_attr}" --apply 'x: builtins.attrNames x' --json | jq -r '.[]'); do
  report_one ".#${host_attr}.${host}.config.system.build.toplevel" "$host" "$host_agg"
done

{
  echo "### Home configs (${system})"
  echo ""
} >> "$per_config_md"
for config in $(nix eval .#homeConfigurations --apply 'x: builtins.attrNames x' --json | jq -r '.[]'); do
  sys=$(nix eval ".#homeConfigurations.\"${config}\".activationPackage.system" --raw 2>/dev/null || true)
  if [ "$sys" = "$system" ]; then
    report_one ".#homeConfigurations.\"${config}\".activationPackage" "$config" "$home_agg"
  fi
done

{
  emit_top20 "$host_agg" "Top 20 derivations by build time (hosts)" time
  emit_top20 "$host_agg" "Top 20 derivations by output size (hosts)" size
  emit_top20 "$home_agg" "Top 20 derivations by build time (home configs)" time
  emit_top20 "$home_agg" "Top 20 derivations by output size (home configs)" size
  cat "$per_config_md"
} >> "$out_md"

if [ -s "$warnings_file" ]; then
  python3 - "$warnings_file" >> "$out_md" <<'PYEOF'
import json
import sys

labels = [(0, "Errors"), (1, "Warnings"), (2, "Notices")]
by_level: dict[int, set[str]] = {0: set(), 1: set(), 2: set()}

with open(sys.argv[1]) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue
        level = data.get("level")
        msg = (data.get("msg") or "").strip()
        if msg and level in by_level:
            by_level[level].add(msg)

if any(by_level.values()):
    print("### Diagnostics")
    print()
    for level, label in labels:
        msgs = sorted(by_level[level])
        if not msgs:
            continue
        print(f"**{label}**")
        print()
        for m in msgs:
            first, *rest = m.splitlines()
            print(f"- {first}")
            for r in rest:
                print(f"  {r}")
        print()
PYEOF
fi
