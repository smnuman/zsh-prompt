# /update_repo — Fully autonomous dated branch + AI commit message + tag + PR

**Description**:
Never touches main. Works on dated branch. Only touches submodules that changed. When you say “done”, Claude itself analyzes the diff and writes a perfect Conventional Commits message → commits → tags → pushes → opens PR → writes ignored summary.

**Usage**:
`/update_repo` → starts session
`/update_repo done` → Claude finishes everything automatically

```bash
#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%Y%m%d)"
BRANCH="update/$DATE"
REPO_NAME="$$ (basename " $$(git rev-parse --show-toplevel)")"
DOCS_FOLDER="docs"
SUMMARY_FILE="$$ DOCS_FOLDER/. $${REPO_NAME}-${DATE}-summary.cc.md"
REMOTE="origin"
DEFAULT_BRANCH="main"

mkdir -p "$DOCS_FOLDER"

ensure_branch() {
  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]]; then
    echo "→ Switching to dated branch: $BRANCH"
    git fetch "$REMOTE" "$BRANCH" || true
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
  fi
}

# Only switch submodules that actually have changes
handle_submodules() {
  git diff --quiet && git diff --cached --quiet || git add -A
  git submodule foreach --quiet '
    if ! git diff --quiet || ! git diff --cached --quiet; then
      echo "Submodule $name changed → using branch $BRANCH"
      git fetch "'"$REMOTE"'" "'"$BRANCH"'" 2>/dev/null || true
      git checkout "'"$BRANCH"'" 2>/dev/null || git checkout -b "'"$BRANCH"'"
    fi
  '
}

if [[ "$$ {1:-}" == "done" || " $${1:-}" == "finish" ]]; then
  echo "→ Finalizing update (asking Claude to write the commit message…)"

  # Stage everything first so diff is complete
  git add -A
  git submodule foreach --quiet 'git add -A 2>/dev/null || true'

  # Let Claude generate the perfect commit message from the full diff
  COMMIT_MSG=$(git diff --staged --submodule=diff | \
    claude --no-input -p "You are an expert git committer. Summarize the changes below as a single Conventional Commits message (feat/fix/chore/refactor/docs/style/test/perf/ci/…) with a short descriptive subject. One line only.

Examples:
  feat(prompt): add pure black & white theme
  fix(zsh): prevent flicker when redrawing right prompt
  chore: bump dependencies

Changes:
" || echo "chore: updates $(date +%Y-%m-%d)")

  echo "Claude chose: $COMMIT_MSG"

  # Commit main repo
  if ! git diff --cached --quiet; then
    git commit -m "$COMMIT_MSG"
  fi

  # Commit only changed submodules with same message
  git submodule foreach --quiet '
    if ! git diff --cached --quiet; then
      git commit -m "'"$COMMIT_MSG"'" && echo "Committed submodule $name"
    fi
  '

  # Tag (simple patch bump)
  LAST_TAG=$$ (git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+ $$' | head -n1 || echo "0.0.0")
  NEW_TAG=$(echo "$LAST_TAG" | awk -F. '{$NF+=1; OFS="."; print $1,$2,$NF}')
  git tag -a "v$NEW_TAG" -m "Release from $BRANCH"

  # Push
  echo "→ Pushing branch + tags"
  git push "$REMOTE" "$BRANCH" --tags -f
  git submodule foreach --quiet 'git push "'"$REMOTE"'" "'"$BRANCH"'" --tags -f 2>/dev/null || true'

  # PR
  if command -v gh >/dev/null; then
    gh pr create --title "$COMMIT_MSG" --body "Automated update from \`$BRANCH\`" --base "$DEFAULT_BRANCH" --head "$BRANCH" --draft || true
  fi

  # Summary
  cat > "$SUMMARY_FILE" <<EOF
# Update Summary — $REPO_NAME — $(date '+%Y-%m-%d')

**Branch**: $BRANCH
**AI commit**: $COMMIT_MSG
**Tag**: v$NEW_TAG

$(git log --oneline "$DEFAULT_BRANCH".."$BRANCH" 2>/dev/null | sed 's/^/• /')

$(git submodule foreach --quiet 'echo -e "\n### $$ name\n $$(git log --oneline '"$DEFAULT_BRANCH"'..'"$BRANCH"' 2>/dev/null | sed "s/^/  • /" || echo "  (no changes)")' 2>/dev/null || true)

Done! PR opened (or draft), summary saved.
EOF

  echo "All finished! Summary → $SUMMARY_FILE"

else
  echo "→ Starting autonomous update session → $BRANCH"
  ensure_branch
  handle_submodules
  echo "You’re on $BRANCH — make your changes."
  echo "When ready → just type: /update_repo done"
  echo "(Claude will write the commit message itself)"
fi
