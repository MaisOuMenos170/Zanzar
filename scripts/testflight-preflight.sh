#!/bin/sh
# Fails when the tree cannot produce a TestFlight build Apple will process.
# Prints release_url=... for GitHub Actions outputs. Does not upload anything.
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

fail() {
  echo "error: $*" >&2
  exit 1
}

note() {
  echo "::warning::$*"
}

pbx="ZanzarProject/ZanzarProject.xcodeproj/project.pbxproj"
plist="ZanzarProject/Info.plist"
release_config="ZanzarProject/Config.Release.xcconfig"
icon="ZanzarProject/ZanzarProject/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
scheme="ZanzarProject/ZanzarProject.xcodeproj/xcshareddata/xcschemes/ZanzarProject.xcscheme"
ci_script="ZanzarProject/ci_scripts/ci_pre_xcodebuild.sh"

[ -f "$pbx" ] || fail "missing $pbx"
[ -f "$plist" ] || fail "missing $plist"
[ -f "$release_config" ] || fail "missing $release_config"
[ -f "$icon" ] || fail "missing app icon $icon"
[ -f "$scheme" ] || fail "scheme ZanzarProject is not shared in git ($scheme)"
[ -x "$ci_script" ] || fail "$ci_script must be executable"

if grep -q 'devplaceholder' "$pbx"; then
  fail "app bundle id is still a devplaceholder"
fi

bundle_count=$(grep -c 'PRODUCT_BUNDLE_IDENTIFIER = dalpra.Zanzar;' "$pbx" || true)
[ "$bundle_count" -ge 2 ] || fail "expected Debug and Release bundle id dalpra.Zanzar"

team_count=$(grep -c 'DEVELOPMENT_TEAM = 982D3NRR89;' "$pbx" || true)
[ "$team_count" -ge 2 ] || fail "expected the app target team 982D3NRR89"

grep -q 'INFOPLIST_KEY_CFBundleDisplayName = Lero;' "$pbx" || fail "display name must be Lero"

grep -q '<key>ITSAppUsesNonExemptEncryption</key>' "$plist" || fail "missing ITSAppUsesNonExemptEncryption"
grep -A1 '<key>ITSAppUsesNonExemptEncryption</key>' "$plist" | grep -q '<false/>' \
  || fail "ITSAppUsesNonExemptEncryption must be false so TestFlight is not Missing Compliance"

grep -q '<key>NSLocationWhenInUseUsageDescription</key>' "$plist" || fail "missing location usage description"
grep -q '<key>CFBundleDisplayName</key>' "$plist" || fail "missing CFBundleDisplayName"
grep -A1 '<key>CFBundleDisplayName</key>' "$plist" | grep -q '<string>Lero</string>' \
  || fail "CFBundleDisplayName must be Lero"

grep -q 'BlueprintName = "ZanzarProject"' "$scheme" || fail "shared scheme does not build ZanzarProject"
grep -q '<ArchiveAction' "$scheme" || fail "shared scheme has no archive action"
grep -q 'buildConfiguration = "Release"' "$scheme" || fail "archive action must use Release"

release_url=$(
  python3 - "$release_config" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
value = ""
for line in text.splitlines():
    stripped = line.strip()
    if stripped.startswith("ZANZAR_API_BASE_URL"):
        value = stripped.split("=", 1)[1].strip()
        break
if not value:
    sys.exit("error: ZANZAR_API_BASE_URL is empty")
# xcconfig writes the scheme separator as :/$()/ so // is not a comment.
value = value.replace(":/$()/", "://", 1)
print(value)
PY
)

case "$release_url" in
  https://*) ;;
  *) fail "release API must be https, got $release_url" ;;
esac

lower=$(printf '%s' "$release_url" | tr '[:upper:]' '[:lower:]')
case "$lower" in
  *localhost*|*127.0.0.1*|*trycloudflare*) fail "release API cannot be a local or tunnel URL: $release_url" ;;
esac

python3 - "$icon" <<'PY'
import struct
import sys

path = sys.argv[1]
data = open(path, "rb").read()
if data[:8] != b"\x89PNG\r\n\x1a\n":
    sys.exit("error: app icon is not a PNG")
if data[12:16] != b"IHDR":
    sys.exit("error: app icon PNG has no IHDR")
width, height = struct.unpack(">II", data[16:24])
color_type = data[25]
# 2 is RGB. 6 is RGBA, which App Store Connect rejects on the 1024 icon.
if (width, height, color_type) != (1024, 1024, 2):
    sys.exit(
        f"error: app icon must be 1024x1024 RGB without alpha, got {width}x{height} color type {color_type}"
    )
PY

if ! grep -q 'deleteAccount\|excluir conta\|apagar conta' \
  ZanzarProject/ZanzarProject/Features/Profile/Views/ProfileView.swift \
  ZanzarProject/ZanzarProject/Resources/Localizable.xcstrings
then
  note "Account deletion is not implemented. Apple requires it before App Store and external TestFlight review. Internal TestFlight processing does not."
fi

echo "release_url=$release_url"
echo "TestFlight preflight passed"
