#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_sf
require_target_org

report_file="$REPORTS_DIR/apex-tests.json"
log "Running Apex tests in org: $SF_TARGET_ORG"
(
  cd "$ROOT_DIR"
  sf apex run test \
    --target-org "$SF_TARGET_ORG" \
    --code-coverage \
    --wait "$SF_WAIT_MINUTES" \
    --result-format json > "$report_file"
)

log "Apex test results written to $report_file"
