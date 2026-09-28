#!/usr/bin/env bash
# Updates the Cloudflare Tunnel API URL used by the iOS app (Debug build only).
# Usage: ./scripts/update-api-tunnel-url.sh https://your-subdomain.trycloudflare.com
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tunnel-url>" >&2
  echo "Example: $0 https://invest-plaza-assessed-lived.trycloudflare.com" >&2
  exit 1
fi

URL="${1%/}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$ROOT_DIR/ZanzarProject/ZanzarProject.xcodeproj/project.pbxproj"

python3 - "$URL" "$PBXPROJ" <<'PY'
import re
import sys

url, path = sys.argv[1], sys.argv[2]
text = open(path).read()
pattern = r'(INFOPLIST_KEY_ZanzarAPIBaseURL = ")[^"]+(";)'
updated, count = re.subn(pattern, rf'\g<1>{url}\2', text, count=1)
if count == 0:
    raise SystemExit("INFOPLIST_KEY_ZanzarAPIBaseURL not found in project.pbxproj")
open(path, "w").write(updated)
print(f"Updated ZanzarAPIBaseURL (Debug) -> {url}")
PY
