---
description: Review the latest weekly flake-update PR and prep for merge or close
allowed-tools: Bash, Read, Edit, Glob, Grep
argument-hint: [run-id]
---

## Task

Review the latest run of `.github/workflows/update.yaml` and the resulting `flake-update` PR. Decide whether to accept (merge) or deny (close), apply any minor fixes locally, post the assessment as a PR comment, and hand off the final `gh pr merge` / `gh pr close` / `git push` to the user.

## Steps

### 1. Locate the run and PR

If `$ARGUMENTS` is non-empty, treat it as the run ID. Otherwise:

```sh
gh run list --workflow=update.yaml --limit 1 \
  --json databaseId,status,conclusion,headBranch,createdAt
gh pr list --head flake-update --state open \
  --json number,url,headRefOid,statusCheckRollup
```

Record the run ID, PR number, and PR URL.

### 2. Download artifacts

Use a fresh per-run temp dir so re-runs do not collide with `file exists`:

```sh
dir=/tmp/flake-review-<run-id>
mkdir -p "$dir"
gh run download <run-id> --dir "$dir"
```

### 3. Read each report

- `update-output/inputs.md` — list of input bumps
- `report-linux/linux-report.md` — closure deltas + built derivations for `nixosConfigurations` and Linux home configs
- `report-darwin/darwin-report.md` — same for `darwinConfigurations` and Darwin home configs

If any job failed, also pull failure logs:

```sh
gh run view <run-id> --log-failed
```

### 4. Diagnose

Categorize the run as one of:

**Broken (deny path)**
Triggered by any of:
- A job in the run failed
- A host or home config build failed inside `build-linux` or `build-darwin`
- A documented upstream regression that needs to be waited out
- Closure jumped in a way that clearly indicates a misconfiguration

Draft this for the user (do not run it):

```sh
gh pr close <num> --comment "<one or two lines: reason + retry plan>"
```

**Clean (accept path)**
All jobs green, closure diffs reasonable, no surprise additions or massive size jumps.

Draft this for the user:

```sh
gh pr merge <num> --squash --delete-branch
```

**Fixable (accept-with-fix path)**
Mostly clean, but a small repo-side change is needed (renamed option, deprecation, dropped package). Apply the edit on `master` locally:

```sh
git checkout master
# edit the offending file(s)
```

The bot's branch is regenerated each weekly run, so fixes belong on master. After the user pushes master and CI passes, they merge the bot PR (next-cycle workflow rebuilds against the fixed master).

### 5. Post assessment as a PR comment

Write a short, plain markdown body to a file and submit:

```sh
gh pr comment <num> --body-file /tmp/flake-review-<run-id>/assessment.md
```

Body content:
- One-line verdict (accept / accept-with-fix / deny)
- Inputs that moved (one line each, no full hashes)
- Closure deltas per config (just the wins/losses, not full tables)
- Fixes applied locally, if any
- Anything left for the user to do

Keep it concise. No AI attribution, no decorative footers.

### 6. Hand-off summary in chat

At the end, print to the user:
- Verdict and reason
- Local files edited (if any), in `path:line` form
- The exact destructive command to run next (`gh pr merge ...` or `gh pr close ...` or `git push ...`)

Do not run any of those yourself. The user lands them manually.

## Notes

- Never amend or force-push the bot's commit on `flake-update`. The workflow regenerates that branch each run.
- Closure-diff entries with no version annotation (just package names) are usually rebuild-only churn from a deeper input change. Note them but don't worry.
- Match the existing repo commit style for any local commits you stage but don't make: lowercase imperative, one short line, no co-author trailers.
