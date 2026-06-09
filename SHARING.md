# Installing World Clock

A tiny menu-bar clock that shows several time zones at once. This is a personal
app shared directly (not from the App Store), so the **first launch needs one
extra step** — after that it just works.

## Requirements

- A Mac running **macOS 14 (Sonoma) or newer**.
- Works on both **Apple Silicon and Intel** Macs.

## Install

1. Double-click **`WorldClock.dmg`** to open it.
2. In the window that appears, **drag `WorldClock.app` onto the `Applications` folder**.
3. Eject the disk image (click the ⏏ next to "World Clock" in Finder).

## First launch (the one extra step)

Because the app isn't from the App Store, macOS blocks it the first time and
shows a message like *"Apple could not verify 'WorldClock' is free of malware."*
This is expected for directly-shared apps. To allow it:

1. Open your **Applications** folder and double-click **WorldClock**.
2. When the warning appears, click **Done** (don't move it to the Trash!).
3. Open **System Settings → Privacy & Security**.
4. Scroll down — you'll see a line saying *"WorldClock was blocked…"* with an
   **Open Anyway** button. Click it.
5. Confirm with Touch ID or your password. If it asks once more, click **Open Anyway**.

That's it — from now on it opens normally every time.

> Prefer the Terminal? You can do the same in one command:
> `xattr -dr com.apple.quarantine /Applications/WorldClock.app`
> then open the app normally.

## Using it

- Look in the **top-right of your menu bar** for a small clock with a time and a
  flag. There is **no Dock icon** — it lives only in the menu bar.
- **Click it** to see the timeline panel: each row is a time zone, the green
  blocks are "awake / reachable" hours, dark is asleep, and the vertical line is
  "right now" across every zone.
- Click **Settings** (gear, bottom-left of the panel) to add/remove zones,
  rename them, choose which zone shows in the menu bar, set 24-hour time, set the
  asleep hours, and turn on **Launch at login**.

## Quitting / uninstalling

- **Quit:** open the panel → **Quit** (bottom-right).
- **Uninstall:** quit it, then drag **WorldClock** from Applications to the Trash.

## Is it safe?

Yes — the warning is just macOS being cautious about apps not distributed through
Apple's paid notarization process; it isn't a sign of anything wrong. If you'd
rather not click through the warning, ask the sender to notarize it (requires a
paid Apple Developer account).
