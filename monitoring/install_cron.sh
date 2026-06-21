#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_SCRIPT="${SCRIPT_DIR}/health_check.sh"
CRON_ENTRY="*/5 * * * * \"${HEALTH_SCRIPT}\""

chmod +x "$HEALTH_SCRIPT"

CURRENT_CRON="$(mktemp)"
UPDATED_CRON="$(mktemp)"
trap 'rm -f "$CURRENT_CRON" "$UPDATED_CRON"' EXIT

crontab -l > "$CURRENT_CRON" 2>/dev/null || true

grep -Fv "$HEALTH_SCRIPT" "$CURRENT_CRON" > "$UPDATED_CRON" || true
echo "$CRON_ENTRY" >> "$UPDATED_CRON"

crontab "$UPDATED_CRON"

echo "Installed cron job:"
echo "$CRON_ENTRY"
