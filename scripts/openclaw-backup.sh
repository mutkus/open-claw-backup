#!/usr/bin/env bash
#
# openclaw-backup.sh
#
# Creates a compressed backup of the OpenClaw data directory (and its
# Postgres database, if one is running in Docker) and writes the archive
# to /tmp. Designed to be run non-interactively over SSH (e.g. from an
# n8n workflow) via a NOPASSWD sudo rule scoped to this exact path.
#
# On success, prints the full path of the created archive as the ONLY
# line on stdout — automation tools should parse that line directly.
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "openclaw-backup.sh must be run as root because /root/.openclaw is root-owned." >&2
  exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
FILE=/tmp/openclaw-backup-$TS.tar.gz
STAGING=$(mktemp -d /tmp/openclaw-backup-$TS.XXXXXX)

cleanup() {
  rm -rf "$STAGING"
}
trap cleanup EXIT

cat > "$STAGING/openclaw-backup-metadata.txt" <<EOF
created_at=$TS
openclaw_data_path=/root/.openclaw
compose_file=not_found
postgres_dump=not_available_no_docker_containers
EOF

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  POSTGRES_CONTAINER=$(docker ps --format '{{.Names}} {{.Image}}' | awk 'tolower($0) ~ /postgres/ {print $1; exit}')
  if [ -n "${POSTGRES_CONTAINER:-}" ]; then
    if docker exec -i "$POSTGRES_CONTAINER" pg_dump -U openclaw openclaw > "$STAGING/openclaw-db-$TS.sql" 2>"$STAGING/openclaw-db-$TS.err"; then
      cat > "$STAGING/openclaw-backup-metadata.txt" <<EOF
created_at=$TS
openclaw_data_path=/root/.openclaw
compose_file=not_found
postgres_container=$POSTGRES_CONTAINER
postgres_db=openclaw
postgres_user=openclaw
postgres_dump=included
EOF
      rm -f "$STAGING/openclaw-db-$TS.err"
    fi
  fi
fi

tar -czf "$FILE" \
  -C / \
  --exclude='root/.openclaw/cache' \
  --exclude='root/.openclaw/locks' \
  --exclude='root/.openclaw/tmp' \
  root/.openclaw \
  -C "$STAGING" .

echo "$FILE"
