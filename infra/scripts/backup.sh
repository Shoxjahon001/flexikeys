#!/usr/bin/env bash
# backup.sh — PostgreSQL backup to S3-compatible storage (MinIO or AWS S3)
#
# Usage:
#   ./infra/scripts/backup.sh            # backup now
#   ./infra/scripts/backup.sh restore    # restore latest
#
# Required env vars:
#   POSTGRES_URL    — postgresql://user:pass@host:port/dbname
#   BACKUP_BUCKET   — s3://your-bucket/flexikeys-backups
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
#   AWS_ENDPOINT_URL — (optional) for MinIO: http://minio:9000
#
# Cron example (daily at 02:00):
#   0 2 * * * /app/infra/scripts/backup.sh >> /var/log/flexikeys-backup.log 2>&1

set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
BACKUP_FILE="flexikeys_${TIMESTAMP}.pgdump"
TMP_FILE="/tmp/${BACKUP_FILE}"

S3_FLAGS=""
if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
  S3_FLAGS="--endpoint-url ${AWS_ENDPOINT_URL}"
fi

# ── Backup ────────────────────────────────────────────────────────────────────

backup() {
  echo "[backup] Starting PostgreSQL dump at ${TIMESTAMP}…"

  pg_dump \
    --format=custom \
    --compress=9 \
    --no-owner \
    --no-acl \
    "${POSTGRES_URL}" \
    --file="${TMP_FILE}"

  echo "[backup] Dump complete: $(du -sh "${TMP_FILE}" | cut -f1)"

  aws s3 cp ${S3_FLAGS} "${TMP_FILE}" "${BACKUP_BUCKET}/${BACKUP_FILE}"

  echo "[backup] Uploaded to ${BACKUP_BUCKET}/${BACKUP_FILE}"

  rm -f "${TMP_FILE}"

  # Prune backups older than 30 days
  CUTOFF=$(date -u -d "30 days ago" +"%Y%m%dT" 2>/dev/null || date -u -v-30d +"%Y%m%dT")
  echo "[backup] Pruning backups older than ${CUTOFF}…"
  aws s3 ls ${S3_FLAGS} "${BACKUP_BUCKET}/" \
    | awk '{print $4}' \
    | grep "^flexikeys_" \
    | while read -r key; do
        prefix="${key:10:14}"  # extract timestamp prefix YYYYMMDDTHHMMSS
        if [[ "${prefix}" < "${CUTOFF}" ]]; then
          echo "[backup] Removing old backup: ${key}"
          aws s3 rm ${S3_FLAGS} "${BACKUP_BUCKET}/${key}"
        fi
      done

  echo "[backup] Done."
}

# ── Restore ───────────────────────────────────────────────────────────────────

restore() {
  echo "[restore] Listing available backups…"
  LATEST=$(aws s3 ls ${S3_FLAGS} "${BACKUP_BUCKET}/" \
    | awk '{print $4}' \
    | grep "^flexikeys_" \
    | sort -r \
    | head -1)

  if [[ -z "${LATEST}" ]]; then
    echo "[restore] No backups found in ${BACKUP_BUCKET}" >&2
    exit 1
  fi

  echo "[restore] Restoring from ${LATEST}…"
  aws s3 cp ${S3_FLAGS} "${BACKUP_BUCKET}/${LATEST}" "${TMP_FILE}"

  pg_restore \
    --format=custom \
    --clean \
    --no-owner \
    --no-acl \
    --dbname="${POSTGRES_URL}" \
    "${TMP_FILE}"

  rm -f "${TMP_FILE}"
  echo "[restore] Restore complete from ${LATEST}."
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "${1:-backup}" in
  backup)  backup  ;;
  restore) restore ;;
  *)
    echo "Usage: $0 [backup|restore]" >&2
    exit 1
    ;;
esac