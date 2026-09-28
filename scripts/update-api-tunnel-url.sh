#!/usr/bin/env bash
# Updates the Cloudflare Tunnel API URL used by the iOS app.
# Usage: ./scripts/update-api-tunnel-url.sh https://your-subdomain.trycloudflare.com
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tunnel-url>" >&2
  echo "Example: $0 https://invest-plaza-assessed-lived.trycloudflare.com" >&2
  exit 1
fi

URL="${1%/}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT="$ROOT_DIR/ZanzarProject/ZanzarProject/Utils/APIConfiguration.swift"

python3 - "$URL" "$SWIFT" <<'PY'
import re
import sys

url, path = sys.argv[1], sys.argv[2]
text = open(path).read()
updated, count = re.subn(
    r'URL\(string: "https?://[^"]+"\)!',
    f'URL(string: "{url}")!',
    text,
    count=1,
)
if count == 0:
    raise SystemExit("defaultBaseURL not found in APIConfiguration.swift")
open(path, "w").write(updated)
print(f"Updated ZanzarAPIBaseURL -> {url}")
PY
