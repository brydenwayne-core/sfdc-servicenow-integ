#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORTS_DIR="${REPORTS_DIR:-$ROOT_DIR/reports}"
SF_WAIT_MINUTES="${SF_WAIT_MINUTES:-30}"
SF_TEST_LEVEL="${SF_TEST_LEVEL:-RunLocalTests}"
SF_TARGET_ORG="${SF_TARGET_ORG:-${TARGET_ORG:-}}"
SF_DEVHUB_ALIAS="${SF_DEVHUB_ALIAS:-${DEVHUB_ALIAS:-}}"

mkdir -p "$REPORTS_DIR"

log() {
  printf '\n[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_sf() {
  require_command sf
}

require_target_org() {
  if [[ -z "$SF_TARGET_ORG" ]]; then
    echo "Set SF_TARGET_ORG (or TARGET_ORG) to the org/alias used for validation." >&2
    exit 1
  fi
}

package_dirs() {
  python3 - <<'PY'
import json
from pathlib import Path
project = json.loads(Path('sfdx-project.json').read_text())
for entry in project.get('packageDirectories', []):
    path = entry.get('path')
    if path:
        print(path)
PY
}

package_names() {
  python3 - <<'PY'
import json
from pathlib import Path
project = json.loads(Path('sfdx-project.json').read_text())
for entry in project.get('packageDirectories', []):
    package = entry.get('package')
    if package:
        print(package)
PY
}

join_by() {
  local delimiter="$1"
  shift
  local first=1
  for item in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$delimiter" "$item"
    fi
  done
}
