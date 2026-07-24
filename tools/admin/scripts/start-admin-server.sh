#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ADMIN_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd -- "${ADMIN_DIR}/../.." && pwd)"
ENV_FILE="${ADMIN_ENV_FILE:-${ADMIN_DIR}/.env.server}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy .env.server.example and configure it." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${ADMIN_HOST:?ADMIN_HOST is required}"
: "${ADMIN_PORT:?ADMIN_PORT is required}"
: "${ADMIN_PIN:?ADMIN_PIN is required}"
: "${SQLITE_PATH:?SQLITE_PATH is required}"
: "${ADMIN_BACKUP_DIR:?ADMIN_BACKUP_DIR is required}"

if [[ "${ADMIN_HOST}" != "127.0.0.1" ]]; then
  echo "ADMIN_HOST must be exactly 127.0.0.1." >&2
  exit 1
fi
if (( ${#ADMIN_PIN} < 6 )); then
  echo "ADMIN_PIN must contain at least 6 characters." >&2
  exit 1
fi
if [[ "${SQLITE_PATH}" != /* ]]; then
  echo "SQLITE_PATH must be absolute." >&2
  exit 1
fi
if [[ ! -f "${SQLITE_PATH}" ]]; then
  echo "Production SQLite database does not exist: ${SQLITE_PATH}" >&2
  exit 1
fi
case "$(basename -- "${SQLITE_PATH}" | tr '[:upper:]' '[:lower:]')" in
  *test*|*smoke*|*temp*|*tmp*) echo "Refusing test or temporary SQLite database." >&2; exit 1 ;;
esac

export NODE_ENV="${NODE_ENV:-production}"
export DATABASE_DRIVER=sqlite
export ADMIN_WEB_ROOT="${ADMIN_WEB_ROOT:-${ADMIN_DIR}/web}"
export SQLITE_BUSY_TIMEOUT_MS="${SQLITE_BUSY_TIMEOUT_MS:-5000}"
mkdir -p -- "${ADMIN_BACKUP_DIR}"

echo "Admin listen address: ${ADMIN_HOST}:${ADMIN_PORT}"
echo "SQLite database: ${SQLITE_PATH}"
echo "Backup directory: ${ADMIN_BACKUP_DIR}"
echo "Environment: ${NODE_ENV}"

cd -- "${REPO_ROOT}/server"
exec node dist/admin/index.js
