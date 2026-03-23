#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

"$(dirname "$0")/static-analysis.sh"
"$(dirname "$0")/apex-tests.sh"
"$(dirname "$0")/validate-metadata.sh"
"$(dirname "$0")/package-checks.sh"
