#!/usr/bin/env bash
# Updates the API base URL used by the iOS app by writing ZANZAR_API_BASE_URL to the
# gitignored ZanzarProject/Config.xcconfig (read into Info.plist at build time).
# Usage: ./scripts/update-api-tunnel-url.sh https://your-subdomain.trycloudflare.com
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tunnel-url>" >&2
  echo "Example: $0 https://invest-plaza-assessed-lived.trycloudflare.com" >&2
  exit 1
fi

URL="${1%/}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT_DIR/ZanzarProject/Config.xcconfig"

python3 - "$URL" "$CONFIG" <<'PY'
import os
import re
import sys

url, path = sys.argv[1], sys.argv[2]
# xcconfig treats "//" as a comment, so the scheme separator is written as ":/$()/".
value = url.replace("://", ":/$()/", 1)
line = f"ZANZAR_API_BASE_URL = {value}"
text = open(path).read() if os.path.exists(path) else ""
updated, count = re.subn(r"^ZANZAR_API_BASE_URL\s*=.*$", lambda _: line, text, count=1, flags=re.M)
if count == 0:
    updated = text.rstrip("\n") + ("\n" if text else "") + line + "\n"
open(path, "w").write(updated)
print(f"Updated ZANZAR_API_BASE_URL in Config.xcconfig -> {url}")
PY
