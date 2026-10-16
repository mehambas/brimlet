# Notifications from other apps

Other apps on the same Mac can show a short notification in Brimlet: a title, a line of text and an SF Symbol for a few seconds, in the small view at the notch. They use the `BrimletIPC` library from this package. The transport is a Unix domain socket owned by the user, `~/Library/Application Support/Brimlet/notification.sock`, resolved from the real home folder so that sandboxed senders reach the same path. There is no TCP or HTTP port, Brimlet is never launched by a sender, and nothing is queued on disk. An earlier draft that used `DistributedNotificationCenter` was dropped, because a bundle identifier claimed in a message proves nothing.

## Pairing

Both sides choose each other explicitly:

1. In Brimlet, **Settings › Modules › Allow an App…** and choose the sender's signed `.app`. **Remove** takes the permission back.
2. In the sender, let the user choose `Brimlet.app` and store its designated requirement.

Each side stores the other app's [designated requirement](https://developer.apple.com/documentation/security/seccodecopydesignatedrequirement(_:_:_:)). On every connection the running peer is checked against it through the audit token the kernel attaches to the socket ([`kSecGuestAttributeAudit`](https://developer.apple.com/documentation/security/ksecguestattributeaudit)) and `SecCodeCheckValidity`; the identifier in the payload only selects which stored permission applies. Both processes must belong to the same user.

A requirement pins the signature. Releases of Brimlet are signed with the same certificate, so the pairing survives updates; a build signed ad hoc changes with every build and has to be chosen again in the sender.

A sandboxed sender needs two temporary exceptions for the socket, both relative to the home folder: a file exception for `/Library/Application Support/Brimlet/notification.sock` and a `temporary-exception.sbpl` rule `(allow network-outbound (home-literal "/Library/Application Support/Brimlet/notification.sock"))`. The file exception alone does not allow connecting. These exceptions are fine for apps distributed outside the App Store; for the App Store, apps sharing an [app group](https://developer.apple.com/documentation/BundleResources/Entitlements/com.apple.security.application-groups) would replace them.

## Wire format

Each connection carries one request and one answer, each a 4-byte big-endian length followed by UTF-8 JSON of at most 8192 bytes. The title holds up to 120 characters, the body 500 and the symbol name 80; the duration is 1 to 30 seconds. Unknown versions or enum values, an empty title and malformed JSON are rejected. The symbol is an SF Symbol name; files, URLs and actions are not accepted.

```json
{
  "id": "UUID",
  "version": 1,
  "sourceBundleID": "com.example.reminders",
  "title": "Time to stretch",
  "body": "You’ve been at your desk for an hour.",
  "symbol": "figure.walk",
  "priority": 1,
  "duration": 6,
  "fallback": "senderDefault"
}
```

The answer is a JSON string: `displayed`, `duplicate`, `busy`, `unavailable`, `unauthorized` or `invalid`. A sender should hold back its own alert only on `displayed` or `duplicate`. Connecting, reading and writing time out after two seconds; without a connection or an answer the sender shows its own alert. `fallback` documents the sender's policy (`senderDefault`, `systemNotification` or `drop`); Brimlet never posts a macOS notification on another app's behalf. The same source and UUID are not shown again for five minutes, and at most 256 deliveries are remembered.

If the answer is lost, or Brimlet quits right after showing the notification, exactly-once delivery across the two processes is not guaranteed. The safe choice is for the sender to show its fallback, which rarely means the notification appears twice. There are no automatic retries.

## Priority

Brimlet keeps what the user is doing: while it is expanded, hidden, in full screen or showing another app's notification, a new one is answered with `busy` or `unavailable` and goes back to the sender. Brimlet does not count a deferred notification as delivered and does not queue it.

- Low (0) is not shown while a module is active.
- Normal (1) takes the small view when nothing else is peeking.
- High (2) may replace a track change peek, but not a calendar or timer alert.

A new calendar or timer alert may end another app's notification. When the notification ends, is dismissed or Brimlet is expanded, the module that was showing before comes back. Pointing at it does not make it last longer.

## Sending from Swift

```swift
import BrimletIPC

let value = ExternalNotification(sourceBundleID: "com.example.reminders",
                                 title: "Time to stretch", body: "You’ve been at your desk for an hour.",
                                 symbol: "figure.walk", fallback: .senderDefault)
// Stored when the user chose Brimlet.app:
let requirement = try ApplicationIdentity.requirement(at: chosenBrimletURL)
let result = await LocalNotificationChannel.send(value, receiverRequirement: requirement)
if !result.delivered { showOwnAlert() }
```

Add the package as a dependency and use the `BrimletIPC` product.

## Tests

- `swift test` covers payload limits, identity checks in both directions on a real socket, a wrong sender and a wrong receiver, a receiver that is not running, and that a file in the socket's place is left alone.
- `bash scripts/test-sandbox-ipc.sh` signs a sandboxed test sender and delivers to a separate test receiver. It touches only temporary files, never either app's settings.
- `--smoke-test` checks presentation, duplicates, the busy, hidden and expanded states, and the return to pinned music. `--capture-previews` renders `external-notification.png`.
