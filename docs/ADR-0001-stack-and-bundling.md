# ADR-0001: Tech stack, app lifecycle, and bundling

Status: Accepted — 2026-06-09

## Context

A personal macOS menu-bar utility that shows several time zones as stacked
timeline strips. Requirements: lives in the menu bar (top-right), no Dock icon,
runs locally, not distributed via the App Store. Build environment is **Command
Line Tools only (no full Xcode)**, Swift 6.3, Apple Silicon, macOS 26.

## Decision

### Language / UI: Swift + SwiftUI, hosted by an AppKit lifecycle

SwiftUI is used for all view content (the popover and settings window). The
**application lifecycle is AppKit**, not SwiftUI's `App`/`MenuBarExtra`.

### Bundling: SwiftPM executable assembled into a `.app` by a shell script

`swift build -c release` produces a bare binary; `scripts/build_app.sh` lays out
a `.app` bundle with an `Info.plist` (`LSUIElement=true`, bundle id, min OS) and
ad-hoc code-signs it. No `.xcodeproj` is required.

## Alternatives considered

1. **SwiftUI `MenuBarExtra` scene (pure SwiftUI lifecycle).** This was the
   first implementation and the obvious "modern" choice. It was **rejected after
   testing**: built as a plain SwiftPM executable (not a full Xcode app),
   `MenuBarExtra` never instantiated its status item — the label view's
   `onAppear` never fired and no menu-bar item appeared. The SwiftUI app
   lifecycle does not reliably bootstrap a status item outside an Xcode-produced
   app bundle. Rather than reverse-engineer the missing bootstrap, we moved to
   the dependable AppKit path.

2. **Electron / web stack.** Rejected: far too heavy for an always-resident
   menu-bar clock; large memory/CPU footprint for a glanceable utility.

3. **Full Xcode project.** Rejected: the environment has only Command Line
   Tools, and a hand-assembled bundle is fully reproducible from the CLI and
   easier to version-control than a `.xcodeproj`.

## Consequences

- **Positive:** Reliable status item via `NSStatusItem`; full control over the
  popover (`NSPopover`) and settings window (`NSWindow` + `NSHostingController`);
  tiny footprint; reproducible CLI build.
- **Positive:** SwiftUI views remain unchanged regardless of lifecycle — the
  timeline/settings code is hosting-agnostic.
- **Negative:** We manage the status-item title refresh and window lifecycle by
  hand (a `Timer` + a Combine subscription to `SettingsStore.objectWillChange`)
  rather than getting it from the SwiftUI scene graph.
- **Negative:** No code-signing/notarization (intentional for personal use).
  First launch may require right-click → Open to clear Gatekeeper.

## Trade-offs explicitly accepted

- Fixed local "night window" (20:00–06:00) for day/night shading instead of real
  sunrise/sunset by geolocation — simpler, no location permission, good enough
  for an at-a-glance awake/asleep cue.
- Status-item title updates once per second via a `Timer`; negligible cost,
  keeps the minute display accurate.
