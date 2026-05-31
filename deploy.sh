#!/usr/bin/env bash
set -euo pipefail

# deploy.sh

# Config
BASEURL="https://alonsopg.github.io/"
DEST="docs"
BRANCH="main"

# Optional local secrets/config. This file is ignored by git.
# Example:
#   PLAUSIBLE_API_KEY="..."
#   PLAUSIBLE_SITE_ID="alonsopg.github.io"
#   PLAUSIBLE_DATE_RANGE="30d"
if [ -f ".analytics.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source ".analytics.env"
  set +a
fi

# Optional private analytics report.
# To enable:
#   1. Create a Plausible site for alonsopg.github.io.
#   2. Enable params.analytics.plausibleEnabled in hugo.toml.
#   3. Put PLAUSIBLE_API_KEY in .analytics.env or export it before running.
print_country_analytics() {
  if [ -z "${PLAUSIBLE_API_KEY:-}" ]; then
    echo "Analytics country report skipped: set PLAUSIBLE_API_KEY in .analytics.env or export it before running."
    return 0
  fi

  command -v curl >/dev/null || {
    echo "Analytics country report skipped: curl not found in PATH."
    return 0
  }
  command -v python3 >/dev/null || {
    echo "Analytics country report skipped: python3 not found in PATH."
    return 0
  }

  local site_id="${PLAUSIBLE_SITE_ID:-alonsopg.github.io}"
  local date_range="${PLAUSIBLE_DATE_RANGE:-30d}"
  local response_file
  response_file="$(mktemp)"

  echo
  echo "Visitor countries from Plausible (site=$site_id, range=$date_range)"

  if ! curl -fsS \
    --request POST \
    --header "Authorization: Bearer ${PLAUSIBLE_API_KEY}" \
    --header "Content-Type: application/json" \
    --url "https://plausible.io/api/v2/query" \
    --data "{
      \"site_id\": \"${site_id}\",
      \"metrics\": [\"visitors\", \"visits\", \"pageviews\"],
      \"date_range\": \"${date_range}\",
      \"dimensions\": [\"visit:country_name\"],
      \"filters\": [[\"is_not\", \"visit:country_name\", [\"\"]]],
      \"order_by\": [[\"visitors\", \"desc\"]],
      \"pagination\": {\"limit\": 50, \"offset\": 0}
    }" > "$response_file"; then
    echo "Could not fetch Plausible analytics. Check PLAUSIBLE_API_KEY and PLAUSIBLE_SITE_ID."
    rm -f "$response_file"
    return 0
  fi

  python3 - "$response_file" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

if payload.get("error"):
    print(f"Plausible API error: {payload['error']}")
    raise SystemExit(0)

rows = payload.get("results", [])
if not rows:
    print("No country data for this range yet.")
    raise SystemExit(0)

print()
print("| Country | Visitors | Visits | Pageviews |")
print("| --- | ---: | ---: | ---: |")
for row in rows:
    country = row.get("dimensions", ["Unknown"])[0] or "Unknown"
    visitors, visits, pageviews = (row.get("metrics", []) + [0, 0, 0])[:3]
    print(f"| {country} | {visitors} | {visits} | {pageviews} |")
PY

  rm -f "$response_file"
  echo
}

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
  print_country_analytics
  exit 0
fi

# Compose a useful message
MSG=${1:-"Update site"}
STAMP="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
git commit -m "$MSG ($STAMP)"

# Push
git push origin "$BRANCH"
echo "Published to https://alonsopg.github.io/"
print_country_analytics
