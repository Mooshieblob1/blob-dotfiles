#!/usr/bin/env bash
set -euo pipefail

# Optional overrides via env:
#   HEADPHONE_PORT, SPEAKER_PORT  (force specific port names)
#   RETRY_COUNT, RETRY_MS         (number of attempts and delay between them)
HEADPHONE_PORT="${HEADPHONE_PORT:-}"
SPEAKER_PORT="${SPEAKER_PORT:-}"
RETRY_COUNT="${RETRY_COUNT:-8}"   # total attempts
RETRY_MS="${RETRY_MS:-200}"       # ms between attempts

RDIR="${XDG_RUNTIME_DIR:-/tmp}"
NID_FILE="$RDIR/audio_output.nid"

DEFAULT_SINK="$(pactl get-default-sink)"

get_active_port() {
  pactl list sinks | awk -v sink="$DEFAULT_SINK" '
    $0 ~ "Name: " sink { in_sink=1 }
    in_sink && /Active Port:/ { print $3; exit }
  '
}

# Discover a reasonable headphones/speakers port if not provided
detect_ports() {
  local in=0
  while IFS= read -r line; do
    if [[ $line == "Name: $DEFAULT_SINK" ]]; then in=1; continue; fi
    [[ $in -eq 0 ]] && continue
    [[ $line =~ ^Sink\ \# ]] && break
    if [[ $line =~ ^[[:space:]]+([a-z0-9._-]+):[[:space:]](.+)\ \(priority ]]; then
      local name="${BASH_REMATCH[1]}"
      local desc="${BASH_REMATCH[2]}"
      local lower="${name,,} ${desc,,}"
      if [[ -z $HEADPHONE_PORT && $lower =~ headphone ]]; then
        HEADPHONE_PORT="$name"
      fi
      if [[ -z $SPEAKER_PORT && ( $lower =~ speaker || $lower =~ lineout || $lower =~ line-out ) ]]; then
        SPEAKER_PORT="$name"
      fi
    fi
  done < <(pactl list sinks)
}

# Resolve an absolute icon path so non-theming notifiers don't show checkerboards
resolve_icon_path() {
  local name="$1"
  # quick cache
  local cache="$RDIR/icon_${name}.path"
  if [[ -f "$cache" ]]; then cat "$cache"; return 0; fi
  local dirs=()
  IFS=: read -ra xdg_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  dirs+=("${xdg_dirs[@]/%//icons}")
  dirs+=("${xdg_dirs[@]/%//pixmaps}")
  dirs+=("/run/current-system/sw/share/icons" "/run/current-system/sw/share/pixmaps")
  local p
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    # Try common extensions, shallow check first
    for ext in png svg xpm; do
      if [[ -f "$d/$name.$ext" ]]; then p="$d/$name.$ext"; break 2; fi
    done
    # Search deeper once per directory
    p="$(command -v find >/dev/null 2>&1 && find "$d" -type f \( -name "$name.png" -o -name "$name.svg" -o -name "$name.xpm" \) -print -quit 2>/dev/null || true)"
    [[ -n "$p" ]] && break
  done
  if [[ -n "$p" ]]; then
    printf '%s' "$p" | tee "$cache" >/dev/null
  fi
}

# Prepare ports
if [[ -z $HEADPHONE_PORT || -z $SPEAKER_PORT ]]; then
  detect_ports
fi

ACTIVE_PORT="$(get_active_port)"

if [[ "$ACTIVE_PORT" == "$HEADPHONE_PORT" ]]; then
  TARGET_PORT="$SPEAKER_PORT"
  TITLE="Audio Output"
  BODY="Switched to Speakers"
  ICON_NAME="audio-speakers-symbolic"
else
  TARGET_PORT="$HEADPHONE_PORT"
  TITLE="Audio Output"
  BODY="Switched to Headphones"
  ICON_NAME="audio-headphones-symbolic"
fi

# Apply the port with verify/retry loop (handles auto-switch policies fighting us)
delay_sec="$(awk -v ms="$RETRY_MS" 'BEGIN{ printf "%.3f", ms/1000 }')"
for ((i=1; i<=RETRY_COUNT; i++)); do
  pactl set-sink-port "$DEFAULT_SINK" "$TARGET_PORT" || true
  sleep "$delay_sec"
  if [[ "$(get_active_port)" == "$TARGET_PORT" ]]; then
    success=1
    break
  fi
done

# Resolve icon path; if not found, omit icon to avoid checkerboard
ICON_PATH="$(resolve_icon_path "$ICON_NAME" || true)"
if [[ -n "${ICON_PATH:-}" ]]; then
  ICON_ARG=(--icon="$ICON_PATH")
else
  ICON_ARG=()
fi

# Stack/replace the notification
LAST_ID="$(cat "$NID_FILE" 2>/dev/null || echo 0)"
NEW_ID="$(notify-send \
  --app-name="Audio Output" \
   \
  --print-id \
  "${ICON_ARG[@]}" \
  "$TITLE" "$BODY")" || true
if [[ -n "${NEW_ID:-}" ]]; then printf '%s' "$NEW_ID" > "$NID_FILE"; fi

# If we failed to hold the port, inform user
if [[ -z "${success:-}" ]]; then
  warn_id="$(notify-send --app-name="Audio Output" --print-id "${ICON_ARG[@]}" "Auto-switch policy" "The system reverted the port after toggling. We tried ${RETRY_COUNT}x. Consider disabling auto jack switching in WirePlumber/PulseAudio.")" || true
  exit 1
fi
