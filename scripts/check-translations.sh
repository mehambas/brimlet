#!/bin/bash
# Compares the strings the compiler finds in the code with Resources/tr.lproj/Localizable.strings:
# reports missing and unused Turkish translations and translations whose placeholders differ.
set -euo pipefail
cd "$(dirname "$0")/.."
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swift build --disable-sandbox --product Brimlet -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc "$work" >/dev/null
plutil -convert json -o "$work/tr.json" Resources/tr.lproj/Localizable.strings
/usr/bin/python3 - "$work" <<'PY'
import glob, json, re, sys
work = sys.argv[1]
keys = set()
for path in glob.glob(work + "/*.stringsdata"):
    for entries in json.load(open(path)).get("tables", {}).values():
        keys.update(entry["key"] for entry in entries)
placeholder = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|f|%)")
# Keys made only of placeholders and symbols read the same in every language.
keys = {key for key in keys if re.search(r"[A-Za-z]", placeholder.sub("", key))}
translations = json.load(open(work + "/tr.json"))
problems = [f"missing: {key!r}" for key in sorted(keys - translations.keys())]
problems += [f"unused: {key!r}" for key in sorted(translations.keys() - keys)]
for key in sorted(keys & translations.keys()):
    if sorted(placeholder.findall(key)) != sorted(placeholder.findall(translations[key])):
        problems.append(f"placeholders differ: {key!r} → {translations[key]!r}")
print("\n".join(problems) or f"All {len(keys)} strings have a Turkish translation.")
sys.exit(1 if problems else 0)
PY
