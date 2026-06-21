#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/health_check.log"
HEALTH_URL="http://localhost/health"
APP_CONTAINER="flask_app_prod"
MAX_LOG_BYTES=1048576
KEEP_LOG_LINES=200
MAX_ATTEMPTS=3
RETRY_SLEEP_SECONDS=5

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

trim_log_if_needed() {
  if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -gt "$MAX_LOG_BYTES" ]; then
    tail -n "$KEEP_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
    mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
}

log() {
  echo "[$(timestamp)] $*" >> "$LOG_FILE"
}

trim_log_if_needed

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    exit 0
  fi

  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    sleep "$RETRY_SLEEP_SECONDS"
  fi
done

log "ERROR health check failed for ${HEALTH_URL} after ${MAX_ATTEMPTS} attempts"

{
  echo "[$(timestamp)] docker ps output:"
  docker ps
  echo "[$(timestamp)] last 40 lines from ${APP_CONTAINER}:"
  docker logs --tail 40 "$APP_CONTAINER" 2>&1
} >> "$LOG_FILE" 2>&1

if docker restart "$APP_CONTAINER" >> "$LOG_FILE" 2>&1; then
  log "Restart attempted for ${APP_CONTAINER}"
else
  log "ERROR restart attempt failed for ${APP_CONTAINER}"
fi

trim_log_if_needed
