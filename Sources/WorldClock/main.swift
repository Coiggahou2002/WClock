import AppKit

// AppKit lifecycle (not SwiftUI's `App`): a pure-SwiftUI `MenuBarExtra` scene
// does not reliably create its status item when the app is built as a plain
// SwiftPM executable rather than a full Xcode app. An explicit NSApplication +
// NSStatusItem is the standard, dependable path for a menu-bar agent.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
app.run()
