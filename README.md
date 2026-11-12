# FreeTune Lite v1.0.1 🎵 (iOS 12+ · iPhone 6 ready)

A **separate, older-iPhone edition** of FreeTune. Built for devices the main app
can't run on: **iPhone 6 / 6 Plus / 5s / SE (1st gen)** with **iOS 12**, and 1 GB
of RAM. This is a full **UIKit** app (SwiftUI doesn't exist on iOS 12), written
callback-based (Swift Concurrency doesn't exist on iOS 12 either).

⚠️ This is an independent app — it does NOT touch or replace the main
**FreeTune** project (`C:\Users\hamda\freetune`, iOS 16+).

## What's inside

- **Music tab**: live Audius trending (**New This Week / Month / Year / All-Time
  Top**) + instant channels (**Malayalam, Kerala, Devotional, Tamil, Chill,
  Hip-Hop**) + unified search (Audius + Jamendo merged)
- **Now Playing**: artwork, seek slider, queue, lock-screen controls
- **Sound**: 5-band EQ (Bass/Low/Mid/High/Air) + concert-hall reverb
  (applies to downloaded songs)
- **Downloads**: Creative Commons Jamendo songs saved offline (needs your free
  client ID — register at dev.jamendo.com, paste in Settings tab)
- **Mini player** floating above the tab bar

## Why iOS 12 and not iOS 9?

Apple dropped iOS 9/10/11 deployment support from Xcode 14 onward — modern
toolchains literally cannot build for iOS 9 anymore. iOS 12 is the floor
(Xcode 16 minimum), and it's also the **newest OS an iPhone 6 can run**
(iOS 12.5.7) — so iOS 12 is the perfect match for iPhone 6.

## RAM-safety (1 GB devices)

- All artwork decoded at display size via `CGImageSource` thumbnails
  (never a full-res cover in memory)
- Bounded `NSCache` (120 entries / 24 MB), 30-track pages, no preloading
- No blur-everywhere UI, no visualizer, flat view hierarchy
- Swift stdlib embedded (`ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`) so it can't
  dyld-crash on iOS 12.0/12.1 devices that lack the Swift runtime in the OS

## Build

Same pipeline as the main app: GitHub Actions builds the unsigned IPA on a
cloud Mac, then Sideloadly on Windows signs + installs with your Apple ID.
See **BUILD-STEPS.md**.

## Bundle IDs

| App | Bundle ID | Min iOS |
|---|---|---|
| FreeTune (main) | `com.mhdhamduuu.freetune` | 16.0 |
| **FreeTune Lite** | `com.mhdhamduuu.freetune.lite` | **12.0** |

You can install **both on the same iPhone** — they're separate apps.
