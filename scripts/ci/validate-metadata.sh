#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_sf
require_target_org

mapfile -t dirs < <(cd "$ROOT_DIR" && package_dirs)
if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "No package directories found in sfdx-project.json" >&2
  exit 1
fi

args=()
for dir in "${dirs[@]}"; do
  args+=(--source-dir "$dir")
done

report_file="$REPORTS_DIR/metadata-validate.txt"
log "Validating metadata deployment to $SF_TARGET_ORG with test level $SF_TEST_LEVEL"
(
  cd "$ROOT_DIR"
  sf project deploy validate \
    --target-org "$SF_TARGET_ORG" \
    --test-level "$SF_TEST_LEVEL" \
    --wait "$SF_WAIT_MINUTES" \
    "${args[@]}"
) | tee "$report_file"

log "Metadata validation output written to $report_file"
