#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/mautrix-appservice}"
ASSUME_YES=0
BRIDGES=()
PLACEHOLDER="This value is generated when generating the registration"

usage() {
  cat <<'EOF'
Usage: rotate-mautrix-appservice-tokens.sh [options] [bridge...]

Backs up the generated Mautrix appservice config/registration files, deletes
them so new as_token/hs_token values are generated, restarts Synapse to load
the new registrations, and starts the bridges again.

If no bridge is specified, all supported bridges are rotated.

Options:
  --yes          Do not prompt for confirmation.
  -h, --help     Show this help.

Supported bridges:
  discord, gmessages, signal, slack, telegram, whatsapp,
  meta-facebook, meta-instagram

Environment overrides:
  BACKUP_DIR     backup directory (default: /var/backups/mautrix-appservice)

This does not rotate the separate double-puppeting appservice token and does
not touch any databases.
EOF
}

registration_file() {
  case "$1" in
    discord) echo "discord.yaml" ;;
    gmessages) echo "gmessages.yaml" ;;
    signal) echo "signal-registration.yaml" ;;
    slack) echo "slack.yaml" ;;
    telegram) echo "telegram-registration.yaml" ;;
    whatsapp) echo "whatsapp-registration.yaml" ;;
    meta-facebook | meta-instagram) echo "meta-registration.yaml" ;;
    *) return 1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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
  BRIDGES=(
    discord
    gmessages
    signal
    slack
    telegram
    whatsapp
    meta-facebook
    meta-instagram
  )
fi

for bridge in "${BRIDGES[@]}"; do
  case "$bridge" in
    discord | gmessages | signal | slack | telegram | whatsapp | meta-facebook | meta-instagram) ;;
    *)
      echo "Unsupported bridge: $bridge" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

if [[ "$ASSUME_YES" -ne 1 ]]; then
  echo "This will generate new appservice tokens for:"
  printf '  %s\n' "${BRIDGES[@]}"
  echo
  echo "Old config/registration files will be backed up to:"
  echo "  $BACKUP_DIR/<timestamp>/"
  echo
  echo "Databases, logins, portals, and crypto state are not touched."
  read -r -p "Continue? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$BACKUP_DIR/$timestamp"

echo "Stopping bridges..."
for bridge in "${BRIDGES[@]}"; do
  service="mautrix-$bridge"
  if systemctl cat "$service" >/dev/null 2>&1; then
    systemctl stop "$service" || true
  fi
done

echo "Backing up generated files..."
for bridge in "${BRIDGES[@]}"; do
  data_dir="/var/lib/mautrix-$bridge"
  reg="$(registration_file "$bridge")"
  backup_dir="$backup_root/$bridge"

  if [[ ! -d "$data_dir" ]]; then
    echo "Skipping $bridge: $data_dir does not exist." >&2
    continue
  fi

  install -d -m 0700 "$backup_dir"

  for file in config.yaml "$reg" config.yaml.tmp "$reg.tmp"; do
    if [[ -e "$data_dir/$file" ]]; then
      mv "$data_dir/$file" "$backup_dir/$file"
      echo "  $data_dir/$file -> $backup_dir/$file"
    fi
  done
done

echo "Generating new registrations..."
for bridge in "${BRIDGES[@]}"; do
  data_dir="/var/lib/mautrix-$bridge"
  reg="$(registration_file "$bridge")"
  service="mautrix-$bridge"

  if [[ ! -d "$data_dir" ]]; then
    continue
  fi

  if [[ "$bridge" == meta-* ]]; then
    unit="mautrix-$bridge-registration.service"
    echo "  $bridge: starting $unit"
    if ! systemctl start "$unit"; then
      echo "Failed to run $unit." >&2
      journalctl -u "$unit" -n 80 --no-pager >&2 || true
      exit 1
    fi
  else
    if ! systemctl cat "$service" >/dev/null 2>&1; then
      echo "Skipping $bridge: $service is not installed." >&2
      continue
    fi

    echo "  $bridge: running $service pre-start"
    systemctl start "$service" || true

    for _ in {1..20}; do
      if [[ -f "$data_dir/$reg" ]]; then
        break
      fi
      sleep 1
    done

    systemctl stop "$service" || true
  fi

  if [[ ! -f "$data_dir/$reg" ]]; then
    echo "Registration file was not generated: $data_dir/$reg" >&2
    exit 1
  fi
done

echo "Restarting Synapse to load the new registrations..."
systemctl restart matrix-synapse.service

if ! systemctl is-active --quiet matrix-synapse.service; then
  echo "Synapse failed to start." >&2
  journalctl -u matrix-synapse.service -n 100 --no-pager >&2 || true
  exit 1
fi

echo "Starting bridges..."
for bridge in "${BRIDGES[@]}"; do
  service="mautrix-$bridge"
  if systemctl cat "$service" >/dev/null 2>&1; then
    systemctl start "$service"
  fi
done

echo "Verifying generated tokens..."
declare -A seen_tokens
failures=()

for bridge in "${BRIDGES[@]}"; do
  reg="/var/lib/mautrix-$bridge/$(registration_file "$bridge")"
  if [[ ! -f "$reg" ]]; then
    failures+=("$bridge: registration file missing")
    continue
  fi

  as_token="$(sed -n 's/^as_token: //p' "$reg" | head -n1)"
  hs_token="$(sed -n 's/^hs_token: //p' "$reg" | head -n1)"

  if [[ -z "$as_token" || -z "$hs_token" || "$as_token" == "$PLACEHOLDER" || "$hs_token" == "$PLACEHOLDER" ]]; then
    failures+=("$bridge: placeholder or empty token")
    continue
  fi

  if [[ -n "${seen_tokens[$as_token]:-}" ]]; then
    failures+=("$bridge: as_token duplicates ${seen_tokens[$as_token]}")
  else
    seen_tokens["$as_token"]="$bridge"
  fi
done

if [[ ${#failures[@]} -ne 0 ]]; then
  echo
  echo "Token verification failed:" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "Token rotation complete."
echo "Backup: $backup_root"
echo
systemctl --no-pager --full status matrix-synapse.service | sed -n '1,12p' || true
for bridge in "${BRIDGES[@]}"; do
  service="mautrix-$bridge"
  if systemctl cat "$service" >/dev/null 2>&1; then
    printf '%-28s %s\n' "$service" "$(systemctl is-active "$service" || true)"
  fi
done
