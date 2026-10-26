# How Brimlet works

Brimlet is a Swift package with three targets:

- `BrimletCore` has no UI: what a module shows (`Activity`, `ModuleID`), which module the small view shows (`ActivityRouter`), the countdown, the notch geometry, calendar events and the release versions of the update check.
- `BrimletIPC` is the local channel for [notifications from other apps](external-notifications.md); other apps can depend on it.
- `Brimlet` is the app: one module class per feature, `AppModel` that ties them together, the island panel in AppKit and the views in SwiftUI.

## The island

`IslandPanelController` places a borderless, non-activating panel at the top of the chosen display, centred on the notch. The notch is measured from the screen's safe area and its auxiliary top areas; displays without one get a 218 pt capsule 8 pt below the top edge. The panel joins all Spaces, sits above full-screen apps when allowed and keeps its top edge fixed while it grows downwards.

The small view shows one module. `ActivityRouter` picks it in this order: a tab the user chose in the open panel, a short alert (a track change, a finished timer, a meeting reminder), music if **Keep music in front** is on, the first active module in the user's order, then the first module. Leaving the panel collapses it after 0.6 seconds, a click outside it at once.

**Hide in full screen** compares the bounds of the front app's windows with the display every two seconds and on app switches. It reads no titles and captures nothing.

## Music

Brimlet controls the Spotify app on the Mac through Apple Events, so it needs the Automation permission for Spotify and nothing else: no Spotify account, no web API. The scripts run one at a time on a background queue with a three-second timeout. While a track plays Brimlet reads the player every two seconds, while paused every five; Spotify's `com.spotify.client.PlaybackStateChanged` notification triggers a read right away, so track changes and play/pause show without waiting. Nothing is read while the music module is off or Spotify is not connected.

Album art is loaded from the HTTPS address Spotify returns for the track. Lyrics come from [LRCLIB](https://lrclib.net) when the lyrics panel is opened, by title, artist and duration; timed lyrics follow the playing line.

## Calendar

The calendar module is off by default. Turning it on asks for full calendar access; EventKit runs on its own actor, reads the next seven days of the selected calendars once a minute and whenever the event store changes or the Mac wakes, and keeps the events in memory only. Cancelled events and events the user declined are left out. Meeting links are taken from the event's URL, location and notes, and only HTTPS links to Google Meet, Zoom, Teams and Webex become **Join** buttons. Reminders are shown once per event, never after it has started. Turning the module off drops the events.

## Tasks, timer and quotes

Tasks and quotes are stored as JSON in the app's preferences. Task reminders are local notifications at 9:00 on the due day; tasks completed more than 30 days ago are removed. The timer keeps a deadline rather than counting ticks, so it stays right across sleep; it ends when Brimlet quits. Quotes come in through the **Add to Brimlet as Quote** service and are shown on a separate panel at the right edge of the screen: quotes not shown yet first, then the one shown longest ago.

## cmux

If [cmux](https://cmux.com) is installed, **Settings › Notifications** offers to show coding sessions that wait for a reply. It is off by default. Brimlet then asks the cmux command line tool every five seconds for workspaces, sessions and notifications and shows a session whose workspace description carries the status `Ready` or `Needs input`. A separate status bridge has to write that status; without one nothing appears. Commands run without a shell.

## Settings and data

Settings, tasks, quotes and paired apps are in the `com.hamzabasaran.brimlet` defaults domain. `~/Library/Application Support/Brimlet` holds the notification socket. Brimlet was called Ada before its first release: on its first launch it copies Ada's settings (`de.hamza.ada`) once, leaving Ada's own settings in place.

## Updates

Brimlet asks GitHub for its latest release 10 seconds after launch and then whenever an hourly tick finds that 24 hours have passed since the last check. The time of the last check is stored, so restarts don't check again, and **Check for updates automatically** in Settings › General turns the check off. The request is `GET https://api.github.com/repos/mehambas/brimlet/releases/latest` on an ephemeral URL session without cookies, cache or credentials, with a 15-second timeout. Besides the address it sends only `User-Agent: Brimlet/<version>`, `Accept-Language: en` and the standard Accept headers: no identifiers, system details or usage data. Any failure (no published release, offline, timeout, rate limit) counts as no news. Automatic checks stay silent about it; **Check for Updates…** in the menu bar menu and **Check Now** in Settings › General always say what they found.

The release's tag (`v0.2.0`) is compared with `CFBundleShortVersionString` number by number, so 0.10.0 is newer than 0.9.0. A newer release puts **Update to 0.2.0…** at the top of the menu bar menu and a row with **Release Notes** and **Download and Install** in Settings › General; the offer is stored until a later check replaces it. **Download and Install** downloads the asset `Brimlet.dmg` to the temporary folder and compares its SHA-256 with the asset `Brimlet.dmg.sha256`. If the checksum is missing or does not match, the download is deleted and the release page opens in the browser instead. A verified disk image opens in Finder and Brimlet quits: it is not notarized, so it cannot replace itself, and Finder won't replace a running app. The user drags the new version to Applications.

To try the whole flow, serve a release from a local server and start a build with the testing variables:

```sh
BRIMLET_FAKE_VERSION=0.0.1 BRIMLET_UPDATE_BASE=http://127.0.0.1:8000 dist/Brimlet.app/Contents/MacOS/Brimlet
```

`BRIMLET_FAKE_VERSION` pretends to be another version. `BRIMLET_UPDATE_BASE` replaces `https://api.github.com/repos/mehambas/brimlet`, so the server answers `/releases/latest` with GitHub's JSON (`tag_name`, `html_url`, and `assets` whose `browser_download_url`s point back to the server). With either variable set, Brimlet checks 10 seconds after launch whatever the last check was, and stores neither the check time nor the offer. Quit the installed Brimlet first: a second copy only brings the first one forward.

## Development

```sh
swift test --disable-sandbox
bash scripts/build.sh
open dist/Brimlet.app
```

`scripts/build.sh` builds a universal app (Apple silicon and Intel) into `dist/Brimlet.app` with the hardened runtime and the entitlements for Apple Events and calendars. macOS ties the Automation and Calendar permissions to the app's signature. An ad hoc signature changes with every build, so macOS asks again after each rebuild. `scripts/make-certificate.sh <backup folder>` creates a self-signed “Brimlet Self-Signed” certificate in the login keychain, which `build.sh` then uses; `BRIMLET_SIGN_IDENTITY` picks another identity, and `-` forces ad hoc signing. Releases must always be signed with the same certificate. Keep the backup the script writes: builds signed with a new certificate lose the permissions users granted and the pairing with apps that send notifications.

### Tests and previews

Core tests cover the countdown across sleep, pause and resume, module routing, the notch geometry, calendar time ranges, sorting and meeting links, reminders, notification payloads and the socket's identity checks, release versions, GitHub answers and checksum files. App tests cover the cmux session filter and the move from Ada's settings. Tests and previews keep their settings in memory and never touch the app's real settings.

```sh
# Sample content only: no real settings, calendars or Spotify data are read.
dist/Brimlet.app/Contents/MacOS/Brimlet -AppleLanguages '(en)' --capture-previews /tmp/brimlet-previews
dist/Brimlet.app/Contents/MacOS/Brimlet --capture-quote-previews /tmp/brimlet-previews
dist/Brimlet.app/Contents/MacOS/Brimlet --smoke-test
```

`--capture-previews` renders the music, lyrics, timer, calendar, peek and notification states and every settings tab. `--smoke-test` opens the real panel on the current display and checks its geometry, navigation, the timer, the calendar module and notifications from other apps; it prints the result and writes it to `brimlet-smoke-test.json` in the temporary folder.

### Translations

Source strings are English. The Turkish translation is `Resources/tr.lproj`: `Localizable.strings` for the interface, `InfoPlist.strings` for the permission prompts and `ServicesMenu.strings` for the Services menu item. `scripts/check-translations.sh` lets the compiler list every localizable string and reports missing or unused translations and placeholders that differ. To see the app in Turkish, start it with `-AppleLanguages '(tr)'`.

### Demo animations

```sh
bash scripts/build.sh && scripts/make-demo.sh
```

`--capture-demo` plays a short session with sample content on a made-up menu bar and saves each step as a frame; `make-demo.sh` turns the frames into `docs/images/demo-dark.gif` and `demo-light.gif` with ffmpeg.

### Icon

`Resources/Icon` holds the icon sources: the 1024 px artwork, simplified artwork for 16 and 32 px, the layers, the menu bar icon and the social preview. `Resources/AppIcon.icon` is the Icon Composer version, built from the main shape and highlight layers with a light and a dark fill; macOS 26 and later derive the tinted and clear styles from it. After changing either, run `scripts/make-icon.sh`: it writes `AppIcon.icns` for macOS 14 and 15 and compiles the `.icon` into `Assets.car` (this needs Xcode 26 or later). Both results are committed, so building the app needs neither Xcode nor the script. To check every style without changing System Settings:

```sh
"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" Resources/AppIcon.icon \
    --export-image --output-file dark.png --platform macOS --rendition Dark --width 512 --height 512 --scale 1
```

The renditions are `Default`, `Dark`, `TintedLight`, `TintedDark`, `ClearLight` and `ClearDark`.

### Releases

```sh
scripts/release.sh 0.2.0
```

The release script sets the version in `Resources/Info.plist`, increments the build number, builds and signs the app with the self-signed certificate, packs it into `dist/Brimlet.dmg` and writes its SHA-256 to `dist/Brimlet.dmg.sha256`. Attach both files to the GitHub release (tag `v0.2.0`) under these names: the README links `releases/latest/download/Brimlet.dmg`, and the update check installs only a disk image whose checksum file it finds next to it.
