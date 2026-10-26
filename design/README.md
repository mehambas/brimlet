# Brimlet — Graphite and Glass

Reference: OpenDesign’s **Brimlet · UI-Redesign**, 26 October 2026, in the `brimlet-icon-20261016` project. The self-contained board is preserved at [reference/brimlet-ui/index.html](reference/brimlet-ui/index.html). Its five pages cover the island, settings, tokens and feature mapping.

Implementation uses native AppKit toolbar tabs and SwiftUI grouped forms. The settings window is 520 pt wide, fits the selected pane and available screen height, and scrolls for longer content. General includes the old Appearance controls; Calendar and Notifications have their own tabs. Module ordering supports dragging as well as the existing accessible up/down actions. System windows follow appearance; the island stays black.

`Theme.swift` contains the logo-derived graphite, mint and adaptive jade colors. Calendar dots read the original calendar color; missing colors omit the dot. No permission, routing, persistence, update or notification delivery behavior is replaced.

Native macOS controls retain system rendering and spacing, so the board’s CSS replicas are not pixel-for-pixel copies. Module rows retain reorder buttons in addition to dragging. Long settings content remains scrollable within the board’s 620 pt content-height limit.

## Verification

```sh
swift test --disable-sandbox --cache-path .build/cache
bash scripts/check-translations.sh
bash scripts/build.sh
bash scripts/capture-design-previews.sh
```

The capture script uses a temporary app with a separate bundle identity and fixture data. It saves light/dark settings and auxiliary windows, island states and quotes in English and Turkish under `design/previews/`. The smoke check verifies module routing, timer pause/reset, calendar disabling, external notification priority and expiry, and all five native settings tabs and their width. It does not connect to Spotify or read real calendars.
