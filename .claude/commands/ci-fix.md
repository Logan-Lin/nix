---
description: Fetch the latest ci.yaml run and fix any eval errors/warnings
allowed-tools: Bash, Read, Edit, Glob, Grep
argument-hint: [run-id]
---

## Task

Review the latest run of `.github/workflows/ci.yaml` and fix every actionable error or warning surfaced by `nix eval`. Stop before committing or pushing.

## Steps

### 1. Resolve the target run

If `$ARGUMENTS` is non-empty, treat it as the run ID. Otherwise pick the most recent run on the current branch:

```sh
branch=$(git branch --show-current)
gh run list --workflow=ci.yaml --branch="$branch" --limit 1 \
  --json databaseId,status,conclusion,headSha,createdAt
```

Record the run ID, conclusion, and head SHA.

### 2. Pull logs and stderr artifacts

For each matrix job (Linux + Darwin), grab the run logs:

```sh
gh run view <run-id> --log
gh run view <run-id> --log-failed   # only if any job failed
```

The actual `nix eval` stderr is uploaded as an artifact per system by `ci.yaml`'s `Upload eval stderr` step. Download both into a temp dir and read them:

```sh
tmp=$(mktemp -d)
gh run download <run-id> -D "$tmp" \
  -n eval-stderr-x86_64-linux \
  -n eval-stderr-aarch64-darwin
ls "$tmp"
cat "$tmp"/*/eval.stderr
```

If a system had no warnings the artifact will be missing or empty — that's fine, skip it. Job/step metadata is still useful for cross-referencing:

```sh
gh api repos/{owner}/{repo}/actions/runs/<run-id>/jobs --jq '.jobs[] | {name, conclusion, html_url}'
```

### 3. Identify and trace each issue

Common categories:
- Removed or renamed nixpkgs/home-manager option after an input bump
- Deprecated option still emitting a warning
- Type mismatch surfaced by an evaluator change
- A package no longer in nixpkgs

For each, locate the source with `Grep` under `modules/`, `hosts/`, `home/`. The repo layout follows the convention of those three top-level dirs plus `flake.nix`.

### 4. Fix in place

Make the smallest change that resolves the warning. Do not refactor surrounding code. If the issue is purely upstream and not user-fixable, document it in the summary and skip rather than monkey-patching.

### 5. Verify locally

Run the same evals the workflow runs:

```sh
nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x' --json
nix eval .#nixosConfigurations \
  --apply 'builtins.mapAttrs (_: v: v.config.system.build.toplevel.drvPath)' \
  --json 1>/dev/null

nix eval .#darwinConfigurations --apply 'x: builtins.attrNames x' --json
nix eval .#darwinConfigurations \
  --apply 'builtins.mapAttrs (_: v: v.config.system.build.toplevel.drvPath)' \
  --json 1>/dev/null
```

For matching home configs, mirror the loop in `ci.yaml:40-47` on the local platform only. Cross-system home eval needs the workflow runner.

### 6. Summarize

Report:
- Run ID, conclusion, and head SHA
- Each warning/error found, in one line: source file, what it was, what was changed
- Anything left for upstream (with reason)

Stop. The user lands the fix manually with their own commit and push.

## Notes

- Keep edits and commit-ready changes minimal. The user will write the commit message.
- Never include AI attribution in any text you produce.
