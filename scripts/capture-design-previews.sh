#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-$PWD/design/previews}"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
preview_root="$(mktemp -d)"
trap 'rm -rf "$preview_root"' EXIT
# A separate bundle identity keeps fixture notifications away from the installed app.
cp -R dist/Brimlet.app "$preview_root/Brimlet.app"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.hamzabasaran.brimlet.design-preview' "$preview_root/Brimlet.app/Contents/Info.plist"
codesign --force --sign - "$preview_root/Brimlet.app"
preview_binary="$preview_root/Brimlet.app/Contents/MacOS/Brimlet"
for language in en tr; do
    "$preview_binary" -AppleLanguages "($language)" --capture-previews "$output/$language"
    "$preview_binary" -AppleLanguages "($language)" --capture-quote-previews "$output/$language"
done
"$preview_binary" --smoke-test
