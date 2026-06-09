import AppKit
import SwiftUI
import Combine
import os

/// Owns the menu bar status item, the popover (hosting `PopoverView`), and the
/// settings window (hosting `SettingsView`). The status item's title is the
/// primary zone's time, refreshed every second.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.rory.worldclock", category: "appdelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "World Clock")
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        statusItem = item

        popover.behavior = .transient
        let host = NSHostingController(
            rootView: PopoverView(openSettings: { [weak self] in self?.openSettings() })
                .environmentObject(settings)
        )
        host.sizingOptions = .preferredContentSize // popover auto-sizes to the SwiftUI content
        popover.contentViewController = host

        updateTitle()
        // The center line tracks "now"; refresh the menu bar title every second.
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateTitle() }
        }
        RunLoop.main.add(t, forMode: .common) // keep ticking while menus/popovers track the run loop
        timer = t

        // Immediately reflect settings changes (primary zone, 24h toggle) in the title.
        settings.objectWillChange
            .sink { [weak self] in
                DispatchQueue.main.async { self?.updateTitle() }
            }
            .store(in: &cancellables)

        logger.log("Status item created; \(self.settings.zones.count, privacy: .public) zone(s) loaded.")
    }

    private func updateTitle() {
        guard let button = statusItem?.button else { return }
        if let zone = settings.primaryZone {
            button.title = " " + TimeText.clock(Date(), in: zone.resolvedTimeZone, use24Hour: settings.use24Hour)
        } else {
            button.title = ""
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func openSettings() {
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView().environmentObject(settings))
            let window = NSWindow(contentViewController: host)
            window.title = "World Clock Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
