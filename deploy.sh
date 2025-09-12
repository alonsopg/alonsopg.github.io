# deploy.sh
#!/usr/bin/env bash
set -euo pipefail

# Config
BASEURL="https://alonsopg.github.io/"
DEST="docs"
BRANCH="main"

# Safety checks
command -v hugo >/dev/null || { echo "hugo not found in PATH"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { echo "Not in a git repo"; exit 1; }
CURR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$CURR_BRANCH" = "$BRANCH" ] || { echo "You're on '$CURR_BRANCH'. Switch to '$BRANCH'."; exit 1; }

# Optional: fetch theme submodules
git submodule update --init --recursive

# Build
echo "Building site → $DEST (baseURL=$BASEURL)"
hugo --minify -D --baseURL "$BASEURL" -d "$DEST"

# Ensure Pages doesn't use Jekyll
touch "$DEST/.nojekyll"

# Stage everything (source + output)
git add -A

# Commit only if there is something new
if git diff --cached --quiet; then
  echo "No changes to publish."
  exit 0
fi

# Compose a useful message
MSG=${1:-"Update site"}
STAMP="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
git commit -m "$MSG ($STAMP)"

# Push
git push origin "$BRANCH"
echo "Published to https://alonsopg.github.io/"
