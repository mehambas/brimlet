#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build --product BrimletIPCProbe
probe_bin="$(swift build --show-bin-path)/BrimletIPCProbe"
probe_dir="$(mktemp -d "$PWD/.build/brimlet-ipc-probe.XXXXXX")"
probe_relative="${probe_dir#"$HOME"}"
if [ "$probe_relative" = "$probe_dir" ]; then
    printf 'Run this test from a checkout under your home directory.\n' >&2
    exit 2
fi
cp "$probe_bin" "$probe_dir/server"
mkdir -p "$probe_dir/Client.app/Contents/MacOS"
cp "$probe_bin" "$probe_dir/Client.app/Contents/MacOS/client"
cp Tests/IPCProbe/Info.plist "$probe_dir/Client.app/Contents/Info.plist"
cp Tests/IPCProbe/Sandbox.entitlements "$probe_dir/client.plist"
/usr/libexec/PlistBuddy -c "Add :com.apple.security.temporary-exception.files.absolute-path.read-write:0 string $probe_dir/" "$probe_dir/client.plist"
/usr/bin/plutil -insert 'com\.apple\.security\.temporary-exception\.sbpl.0' -string "(allow network-outbound (home-literal \"$probe_relative/test.sock\"))" "$probe_dir/client.plist"
/usr/bin/codesign --force --sign - "$probe_dir/server"
/usr/bin/codesign --force --sign - --entitlements "$probe_dir/client.plist" "$probe_dir/Client.app"
"$probe_dir/server" server "$probe_dir/test.sock" "$probe_dir/Client.app" &
probe_pid=$!
trap 'kill "$probe_pid" 2>/dev/null || true' EXIT
for attempt in {1..50}; do
    [ -S "$probe_dir/test.sock" ] && break
    sleep 0.1
done
"$probe_dir/Client.app/Contents/MacOS/client" client "$probe_dir/test.sock" "$probe_dir/server"
printf 'Probe artifacts: %s\n' "$probe_dir"
