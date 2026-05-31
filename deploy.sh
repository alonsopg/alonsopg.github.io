#!/usr/bin/env bash
set -euo pipefail

# deploy.sh

# Config
BASEURL="https://alonsopg.github.io/"
DEST="docs"
BRANCH="main"

# Optional local secrets/config. This file is ignored by git.
# Example:
#   GOATCOUNTER_API_KEY="..."
#   GOATCOUNTER_CODE="alonsopg"
if [ -f ".analytics.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source ".analytics.env"
  set +a
fi

# Optional private analytics report.
# To enable:
#   1. Create/claim https://alonsopg.goatcounter.com.
#   2. Keep params.analytics.goatCounterEnabled = true in hugo.toml.
#   3. Optional: put GOATCOUNTER_API_KEY in .analytics.env to print a country table.
print_country_analytics() {
  local site_code="${GOATCOUNTER_CODE:-alonsopg}"

  if ! grep -Eq '^[[:space:]]*goatCounterEnabled[[:space:]]*=[[:space:]]*true' "hugo.toml"; then
    echo "Analytics tracking is disabled: set goatCounterEnabled = true in hugo.toml."
  fi

  if [ -z "${GOATCOUNTER_API_KEY:-}" ]; then
    echo "GoatCounter dashboard: https://${site_code}.goatcounter.com"
    echo "Country table skipped: set GOATCOUNTER_API_KEY in .analytics.env to print it during deploy."
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

  local api="https://${site_code}.goatcounter.com/api/v0"
  local response_file
  local export_file
  response_file="$(mktemp)"
  export_file="$(mktemp)"

  echo
  echo "Visitor countries from GoatCounter (site=${site_code})"

  if ! curl -fsS \
    --request POST \
    --header "Authorization: Bearer ${GOATCOUNTER_API_KEY}" \
    --header "Content-Type: application/json" \
    --url "${api}/export" > "$response_file"; then
    echo "Could not start GoatCounter export. Check GOATCOUNTER_API_KEY and GOATCOUNTER_CODE."
    rm -f "$response_file" "$export_file"
    return 0
  fi

  local export_id
  export_id="$(python3 - "$response_file" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)
print(payload.get("id", ""))
PY
)"

  if [ -z "$export_id" ]; then
    echo "Could not read GoatCounter export id."
    rm -f "$response_file" "$export_file"
    return 0
  fi

  for _ in 1 2 3 4 5 6 7 8 9 10; do
    curl -fsS \
      --header "Authorization: Bearer ${GOATCOUNTER_API_KEY}" \
      --header "Content-Type: application/json" \
      --url "${api}/export/${export_id}" > "$response_file" || true

    if python3 - "$response_file" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)
raise SystemExit(0 if payload.get("finished_at") else 1)
PY
    then
      break
    fi
    sleep 2
  done

  if ! curl -fsS \
    --header "Authorization: Bearer ${GOATCOUNTER_API_KEY}" \
    --url "${api}/export/${export_id}/download" > "$export_file"; then
    echo "Could not download GoatCounter export. Exports can be rate-limited; try again later."
    rm -f "$response_file" "$export_file"
    return 0
  fi

  python3 - "$export_file" <<'PY'
import csv
import gzip
import io
import sys
from collections import Counter, defaultdict

with open(sys.argv[1], "rb") as handle:
    raw = handle.read()

if raw[:2] == b"\x1f\x8b":
    raw = gzip.decompress(raw)

reader = csv.DictReader(io.StringIO(raw.decode("utf-8", errors="replace")))
pageviews = Counter()
sessions = defaultdict(set)

for row in reader:
    location = (row.get("Location") or "Unknown").strip() or "Unknown"
    country = location.split("-", 1)[0] if location != "Unknown" else "Unknown"
    session = (row.get("Session") or "").strip()
    pageviews[country] += 1
    if session:
        sessions[country].add(session)

if not pageviews:
    print("No country data exported yet.")
    raise SystemExit(0)

print()
print("| Country | Visitors | Pageviews |")
print("| --- | ---: | ---: |")
for country, views in pageviews.most_common(50):
    print(f"| {country} | {len(sessions[country])} | {views} |")
PY

  rm -f "$response_file" "$export_file"
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
