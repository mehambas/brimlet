#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-module-cache"
build=(swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release --arch arm64 --arch x86_64 --product Brimlet)
"${build[@]}"
binary_dir="$("${build[@]}" --show-bin-path)"
app_path="$PWD/dist/Brimlet.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
# A new inode keeps macOS from holding on to the previous executable's code signature.
cp "$binary_dir/Brimlet" "$app_path/Contents/MacOS/Brimlet.new"
mv -f "$app_path/Contents/MacOS/Brimlet.new" "$app_path/Contents/MacOS/Brimlet"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
cp Resources/AppIcon.icns Resources/Assets.car Resources/MenuBarIconTemplate.png Resources/MenuBarIconTemplate@2x.png "$app_path/Contents/Resources/"
rm -rf "$app_path/Contents/Resources/tr.lproj"
cp -R Resources/tr.lproj "$app_path/Contents/Resources/"
# An ad hoc signature changes with every build, and macOS then asks for Calendar and Automation access again.
# The self-signed certificate from scripts/make-certificate.sh keeps the identity stable;
# BRIMLET_SIGN_IDENTITY picks another one, - forces ad hoc signing.
identity="${BRIMLET_SIGN_IDENTITY:-$(security find-identity -p codesigning | awk -F'"' '$2 == "Brimlet Self-Signed" { print $2; exit }')}"
codesign --force --sign "${identity:--}" --identifier com.hamzabasaran.brimlet --timestamp=none \
    --options runtime --entitlements Resources/Brimlet.entitlements "$app_path"
codesign --verify --strict "$app_path"
# Under the hardened runtime macOS suppresses the Calendar prompt when the signed app lacks this entitlement.
codesign --display --entitlements - --xml "$app_path" 2>/dev/null | grep -q 'com.apple.security.personal-information.calendars' \
    || { echo "The signed app is missing the calendar entitlement." >&2; exit 1; }
printf 'Built: %s (%s, signed: %s)\n' "$app_path" "$(lipo -archs "$app_path/Contents/MacOS/Brimlet")" "${identity:-ad hoc}"
