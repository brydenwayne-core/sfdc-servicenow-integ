#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_sf

mapfile -t package_dirs_list < <(cd "$ROOT_DIR" && package_dirs)
if [[ ${#package_dirs_list[@]} -eq 0 ]]; then
  echo "No package directories found in sfdx-project.json" >&2
  exit 1
fi

mapfile -t package_names_list < <(cd "$ROOT_DIR" && package_names)
if [[ ${#package_names_list[@]} -eq 0 ]]; then
  echo "No package names found in sfdx-project.json" >&2
  exit 1
fi

manifest_args=()
for dir in "${package_dirs_list[@]}"; do
  manifest_args+=(--source-dir "$dir")
done

report_file="$REPORTS_DIR/package-checks.txt"
: > "$report_file"

log "Checking package directory configuration"
(
  cd "$ROOT_DIR"
  sf project generate manifest "${manifest_args[@]}" --output-dir "$REPORTS_DIR/generated-manifest"
) >> "$report_file" 2>&1

if [[ -n "$SF_DEVHUB_ALIAS" ]]; then
  log "Running package version creation list checks against Dev Hub: $SF_DEVHUB_ALIAS"
  for package_name in "${package_names_list[@]}"; do
    (
      cd "$ROOT_DIR"
      sf package version create list --package "$package_name" --target-dev-hub "$SF_DEVHUB_ALIAS"
    ) >> "$report_file" 2>&1
  done
else
  log "SF_DEVHUB_ALIAS not set; skipped Dev Hub package version checks"
  echo "SF_DEVHUB_ALIAS not set; skipped Dev Hub package version checks" >> "$report_file"
fi

log "Package check output written to $report_file"
