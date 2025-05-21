#!/bin/bash
set -euo pipefail

# === Configuration ===
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DUMP_DIR="/tmp/db_dumps"
ARCHIVE_NAME="backup_${DATE}.tar.gz"
ARCHIVE_PATH="/tmp/${ARCHIVE_NAME}"

# === Required environment variables ===
: "${SUPABASE_DB_URI?Missing SUPABASE_DB_URI}" # e.g. postgres://user:password@host:port/dbname
: "${RCLONE_REMOTE?Missing RCLONE_REMOTE}" # e.g. remote:/supabase_backups

# === Prepare directories ===
mkdir -p "$DUMP_DIR"
cd "$DUMP_DIR"

echo "📄 Dumping roles..."
supabase db dump --db-url "$SUPABASE_DB_URI" -f roles.sql --role-only

echo "📄 Dumping schema..."
supabase db dump --db-url "$SUPABASE_DB_URI" -f schema.sql

echo "📄 Dumping data..."
supabase db dump --db-url "$SUPABASE_DB_URI" -f data.sql --data-only --use-copy

# === Archive the dump files ===
echo "Creating archive $ARCHIVE_NAME..."
tar -czf "$ARCHIVE_PATH" roles.sql schema.sql data.sql

# === Upload via rclone ===
echo "Uploading archive via rclone..."
rclone copy "$ARCHIVE_PATH" "$RCLONE_REMOTE" --progress

# === Optional: Delete old backups ===
# Delete files older than this in s or suffix ms|s|m|h|d|w|M|y
DELETE_OLDER_THAN_X="${DELETE_OLDER_THAN_X:-}"
if [[ -n "$DELETE_OLDER_THAN_X" ]]; then
  echo "Deleting remote backups older than $DELETE_OLDER_THAN_X..."
  rclone delete "$RCLONE_REMOTE" --min-age "$DELETE_OLDER_THAN_X" -v
fi

# === Cleanup ===
echo "Cleaning up temporary files..."
rm -rf "$DUMP_DIR" "$ARCHIVE_PATH"

echo "Backup complete: $ARCHIVE_NAME"
