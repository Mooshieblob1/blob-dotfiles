#!/usr/bin/env bash
set -euo pipefail

QS_BIN="$(command -v qs)"
QS_QML="$HOME/.config/quickshell/ii/shell.qml"

# Find all ii QuickShell PIDs robustly (covers different launch methods and paths)
pids() {
  ps -u "$USER" -o pid=,comm=,args= | awk '
    /qs[[:space:]].*-p[[:space:]].*quickshell\/ii\/shell\.qml/ ||
    /qs[[:space:]].*-c[[:space:]]ii/ ||
    /quickshell\/ii\/shell\.qml/ {print $1}'
}

# Graceful stop
mapfile -t P < <(pids)
if (( ${#P[@]} )); then
  kill -TERM "${P[@]}" 2>/dev/null || true
  sleep 0.6
fi

# Force stop leftovers
mapfile -t P2 < <(pids)
if (( ${#P2[@]} )); then
  kill -KILL "${P2[@]}" 2>/dev/null || true
  sleep 0.2
fi

# Start a single instance
exec "$QS_BIN" -p "$QS_QML"
