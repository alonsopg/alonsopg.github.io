# deploy.sh
#!/usr/bin/env bash
set -euo pipefail

# Config — change if you ever move repos
BASEURL="https://alonsopg.github.io/"
DEST="docs"
BRANCH="main"

# Sanity checks
command -v hugo >/dev/null || { echo "hugo not found in PATH"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { echo "Not in a git repo"; exit 1; }
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  echo "You're on '$CURRENT_BRANCH'. Switch to '$BRANCH' (git checkout $BRANCH)"; exit 1
fi

# Build (forces correct baseURL and target dir regardless of hugo.toml)
echo "Building site → $DEST with baseURL=$BASEURL"
hugo --minify -D --baseURL "$BASEURL" -d "$DEST"

# Ensure Pages doesn't run Jekyll on the output
touch "$DEST/.nojekyll"

# Commit only if there are changes in docs/
if git diff --quiet -- "$DEST"; then
  echo "No changes to publish."
else
  git add "$DEST"
  git commit -m "Publish $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git push origin "$BRANCH"
  echo "Published to $BRANCH:$DEST"
fi

echo "Done. Now make sure GitHub Pages is set to: Source=Deploy from a branch, Branch=$BRANCH, Folder=/docs"
