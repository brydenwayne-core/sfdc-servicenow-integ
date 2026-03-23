#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_sf
require_command java

mapfile -t dirs < <(cd "$ROOT_DIR" && package_dirs)
if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "No package directories found in sfdx-project.json" >&2
  exit 1
fi

targets=$(join_by "," "${dirs[@]}")
report_file="$REPORTS_DIR/static-analysis.json"

log "Running Salesforce Code Analyzer against: $targets"
(
  cd "$ROOT_DIR"
  sf scanner run \
    --target "$targets" \
    --engine "pmd,eslint-lwc,retire-js" \
    --severity-threshold 3 \
    --format json \
    --outfile "$report_file"
)

log "Static analysis report written to $report_file"
