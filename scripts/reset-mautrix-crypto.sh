#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/mautrix}"
PSQL="${PSQL:-/run/current-system/sw/bin/psql}"
PG_DUMP="${PG_DUMP:-/run/current-system/sw/bin/pg_dump}"
DO_START=1
DO_BACKUP=1
ASSUME_YES=0
BRIDGES=()

usage() {
  cat <<'EOF'
Usage: reset-mautrix-crypto.sh [options] [bridge...]

Stops each bridge, backs up its database, drops every crypto_* table
(including crypto_version), and optionally restarts the bridge. The next
start recreates the crypto schema and a fresh Matrix device using the pickle
key currently configured in sops.

If no bridge is specified, slack and whatsapp are reset.

Options:
  --no-start     Do not start the bridge(s) after clearing crypto state.
  --skip-backup  Skip the pg_dump backup (not recommended).
  --yes          Do not prompt for confirmation.
  -h, --help     Show this help.

Supported bridges:
  slack, whatsapp, gmessages, signal, meta-facebook, meta-instagram

Environment overrides:
  BACKUP_DIR     backup directory (default: /var/backups/mautrix)
  PSQL           psql binary (default: /run/current-system/sw/bin/psql)
  PG_DUMP        pg_dump binary (default: /run/current-system/sw/bin/pg_dump)

Examples:
  sudo ./reset-mautrix-crypto.sh
  sudo ./reset-mautrix-crypto.sh whatsapp
  sudo ./reset-mautrix-crypto.sh gmessages signal
  sudo ./reset-mautrix-crypto.sh meta-facebook meta-instagram
  sudo ./reset-mautrix-crypto.sh --no-start slack whatsapp
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-start)
      DO_START=0
      shift
      ;;
    --skip-backup)
      DO_BACKUP=0
      shift
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      BRIDGES+=("$1")
      shift
      ;;
  esac
done

if [[ ${#BRIDGES[@]} -eq 0 ]]; then
  BRIDGES=(slack whatsapp)
fi

for bridge in "${BRIDGES[@]}"; do
  case "$bridge" in
    slack|whatsapp|gmessages|signal|meta-facebook|meta-instagram) ;;
    *)
      echo "Unsupported bridge: $bridge (supported: slack, whatsapp, gmessages, signal, meta-facebook, meta-instagram)" >&2
      exit 1
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

if [[ "$ASSUME_YES" -ne 1 ]]; then
  echo "This will delete all crypto state for: ${BRIDGES[*]}"
  echo "Messages, portals, and logins are kept; only crypto_* tables are dropped."
  read -r -p "Continue? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

if [[ "$DO_BACKUP" -eq 1 ]]; then
  install -d -m 0700 "$BACKUP_DIR"
fi

pickle_env=/run/secrets/rendered/mautrix-pickle-keys.env
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
failures=()

for bridge in "${BRIDGES[@]}"; do
  service="mautrix-$bridge"
  db="mautrix-$bridge"
  case "$bridge" in
    meta-facebook|meta-instagram)
      # Both Meta instances share the single mautrix.meta.pickle_key secret.
      env_var=MAUTRIX_META_PICKLE_KEY
      sops_bridge=meta
      ;;
    *)
      env_var="MAUTRIX_$(printf '%s' "$bridge" | tr '[:lower:]' '[:upper:]')_PICKLE_KEY"
      sops_bridge="$bridge"
      ;;
  esac

  echo
  echo "=== $bridge ==="

  if ! sudo -u postgres "$PSQL" -d "$db" -Atc 'SELECT 1' >/dev/null 2>&1; then
    echo "Database $db does not exist; skipping $bridge." >&2
    continue
  fi

  service_installed=0
  if systemctl cat "$service" >/dev/null 2>&1; then
    service_installed=1
    echo "Stopping $service..."
    if ! systemctl stop "$service"; then
      echo "Failed to stop $service; skipping $bridge." >&2
      failures+=("$bridge: failed to stop $service")
      continue
    fi
  else
    echo "$service is not installed; skipping service stop."
  fi

  if [[ "$DO_BACKUP" -eq 1 ]]; then
    backup_file="$BACKUP_DIR/$bridge-$timestamp.dump"
    echo "Backing up $db to $backup_file..."
    # Write via root's stdout so pg_dump doesn't need write access to the
    # root-owned backup directory.
    # shellcheck disable=SC2024 # redirection is intentionally done by the root shell
    if ! (umask 077; sudo -u postgres "$PG_DUMP" -Fc -d "$db" > "$backup_file"); then
      rm -f "$backup_file"
      echo "Backup failed; not dropping crypto tables for $db." >&2
      failures+=("$bridge: backup failed")
      if [[ "$DO_START" -eq 1 && "$service_installed" -eq 1 ]]; then
        systemctl start "$service" || true
      fi
      continue
    fi
    echo "Backup written to $backup_file"
  fi

  echo "Dropping crypto state for $db..."
  tables="$(
    sudo -u postgres "$PSQL" -d "$db" -Atc "
      SELECT string_agg(format('%I', tablename), ', ' ORDER BY tablename)
      FROM pg_tables
      WHERE schemaname = 'public'
        AND tablename LIKE 'crypto\\_%'
    "
  )"

  if [[ -z "$tables" ]]; then
    echo "No crypto_* tables found in $db; nothing to drop."
  elif ! sudo -u postgres "$PSQL" -d "$db" -v ON_ERROR_STOP=1 \
    -c "DROP TABLE $tables CASCADE;"; then
    echo "Failed to drop crypto tables for $db." >&2
    failures+=("$bridge: failed to drop crypto tables")
    if [[ "$DO_START" -eq 1 && "$service_installed" -eq 1 ]]; then
      systemctl start "$service" || true
    fi
    continue
  else
    echo "Dropped: $tables"
  fi

  pickle_env_ok=0
  if [[ -r "$pickle_env" ]] && grep -q "^$env_var=" "$pickle_env"; then
    pickle_env_ok=1
  else
    echo "WARNING: $pickle_env does not contain $env_var." >&2
    echo "         Set sops > mautrix > $sops_bridge > pickle_key and deploy it." >&2
  fi

  echo "Note: the old Matrix device may still exist on the homeserver."
  echo "      It is no longer used after this reset and can be removed manually."

  if [[ "$DO_START" -eq 1 ]]; then
    if [[ "$service_installed" -eq 0 ]]; then
      echo "$service is not installed; not starting it."
    elif [[ "$pickle_env_ok" -ne 1 ]]; then
      echo "Refusing to start $service until the pickle key is deployed." >&2
      failures+=("$bridge: pickle key $env_var missing")
      continue
    else
      echo "Starting $service..."
      if ! systemctl start "$service"; then
        echo "Failed to start $service." >&2
        failures+=("$bridge: failed to start $service")
        continue
      fi
      systemctl --no-pager --full status "$service" | sed -n '1,15p' || true
    fi
  else
    echo "Crypto state reset. Start with: systemctl start $service"
  fi
done

if [[ ${#failures[@]} -ne 0 ]]; then
  echo
  echo "Completed with errors:" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi
