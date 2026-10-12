#!/bin/sh
# Prints an xcodebuild destination. Prefers iPhone 17, otherwise the first
# available iPhone, so a GitHub runner image rename does not fail the job.
set -eu

preferred="iPhone 17"
devices=$(xcrun simctl list devices available)

names=$(printf '%s\n' "$devices" | sed -n 's/^[[:space:]]*\(iPhone[^(]*\) ([0-9A-Fa-f-]\{36\}).*/\1/p' | sed 's/[[:space:]]*$//')

if [ -z "$names" ]; then
  echo "error: no available iPhone simulators" >&2
  printf '%s\n' "$devices" >&2
  exit 1
fi

if printf '%s\n' "$names" | grep -qx "$preferred"; then
  chosen=$preferred
else
  chosen=$(printf '%s\n' "$names" | head -n 1)
  echo "warning: $preferred is not installed; using $chosen" >&2
fi

echo "platform=iOS Simulator,name=${chosen},OS=latest"
