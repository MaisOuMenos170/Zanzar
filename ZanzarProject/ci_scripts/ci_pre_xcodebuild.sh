#!/bin/sh
# Xcode Cloud runs this before archive. The App Store rejects a second upload
# with the same CFBundleVersion, so the committed version stays 1 for local
# builds and this script stamps the Xcode Cloud build number onto the app.
set -eu

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "error: CI_BUILD_NUMBER is not set" >&2
  exit 1
fi

cd "${CI_PRIMARY_REPOSITORY_PATH}/ZanzarProject"
xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
