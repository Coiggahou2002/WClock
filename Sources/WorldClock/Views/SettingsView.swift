import SwiftUI
import ServiceManagement
import os

/// Settings window: manage the zone list and display preferences.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var showingAddSheet = false
    @State private var launchAtLogin = false
    @State private var loginError: String?

    private let logger = Logger(subsystem: "com.rory.worldclock", category: "settings-ui")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Time Zones")
                .font(.headline)

            zoneList

            HStack {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Zone", systemImage: "plus")
                }
                Spacer()
                Text("Drag to reorder · star = menu bar zone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Display").font(.headline)
            Toggle("Use 24-hour time", isOn: $settings.use24Hour)
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(enabled: newValue)
                }
            if let loginError {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }

            Divider()

            sleepSection
        }
        .padding(20)
        .frame(width: 420, height: 580)
        .sheet(isPresented: $showingAddSheet) {
            AddZoneSheet { identifier in
                settings.addZone(identifier: identifier)
            }
        }
        .onAppear {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep / Awake").font(.headline)
            Text("Hours shaded as asleep (dark) on every strip. Wraps past midnight.")
                .font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text("Asleep from")
                Picker("", selection: $settings.asleepStartHour) {
                    ForEach(0..<24, id: \.self) { Text(hourLabel($0)).tag($0) }
                }
                .labelsHidden().frame(width: 92)
                Text("to")
                Picker("", selection: $settings.asleepEndHour) {
                    ForEach(0..<24, id: \.self) { Text(hourLabel($0)).tag($0) }
                }
                .labelsHidden().frame(width: 92)
            }

            Text(asleepCaption).font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text("Quick:").font(.caption).foregroundStyle(.secondary)
                quickButton("Default", start: 0, end: 8)
                quickButton("Early bird", start: 22, end: 6)
                quickButton("Night owl", start: 2, end: 10)
            }
        }
    }

    private func quickButton(_ title: String, start: Int, end: Int) -> some View {
        Button(title) {
            settings.asleepStartHour = start
            settings.asleepEndHour = end
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    /// Hours asleep, accounting for the midnight wrap.
    private var asleepDuration: Int {
        let s = settings.asleepStartHour, e = settings.asleepEndHour
        if s == e { return 0 }
        return e > s ? e - s : 24 - s + e
    }

    private var asleepCaption: String {
        guard asleepDuration > 0 else { return "No asleep hours set (whole strip shown awake)." }
        return "Asleep \(hourLabel(settings.asleepStartHour))–\(hourLabel(settings.asleepEndHour)) · \(asleepDuration)h"
    }

    private func hourLabel(_ hour: Int) -> String {
        if settings.use24Hour { return String(format: "%02d:00", hour) }
        let period = hour < 12 ? "AM" : "PM"
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return "\(h12) \(period)"
    }

    private var zoneList: some View {
        List {
            ForEach(settings.zones) { zone in
                HStack(spacing: 8) {
                    Button {
                        settings.primaryZoneID = zone.id
                    } label: {
                        Image(systemName: zone.id == settings.primaryZoneID ? "star.fill" : "star")
                            .foregroundStyle(zone.id == settings.primaryZoneID ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Show this zone in the menu bar")

                    Text(FlagProvider.flag(for: zone.timeZoneIdentifier))
                        .font(.system(size: 15))

                    TextField("Name", text: labelBinding(for: zone))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)

                    Text(zone.timeZoneIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .onDelete { settings.removeZones(at: $0) }
            .onMove { settings.moveZones(from: $0, to: $1) }
        }
        .frame(minHeight: 180)
    }

    private func labelBinding(for zone: ClockZone) -> Binding<String> {
        Binding(
            get: { settings.zones.first(where: { $0.id == zone.id })?.label ?? "" },
            set: { newValue in
                if let idx = settings.zones.firstIndex(where: { $0.id == zone.id }) {
                    settings.zones[idx].label = newValue
                }
            }
        )
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            logger.error("Launch-at-login toggle failed: \(error.localizedDescription, privacy: .public)")
            loginError = "Couldn't change login item. The app may need to live in /Applications."
            // Revert the toggle to reflect the real state.
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }
}

/// Searchable list of all IANA zones for adding a new clock.
struct AddZoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let onAdd: (String) -> Void

    private var allIdentifiers: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return allIdentifiers }
        return allIdentifiers.filter { $0.lowercased().contains(q) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Time Zone").font(.headline)
            TextField("Search (e.g. Tokyo, London, +05)", text: $query)
                .textFieldStyle(.roundedBorder)

            List(filtered, id: \.self) { id in
                Button {
                    onAdd(id)
                    dismiss()
                } label: {
                    HStack {
                        Text(FlagProvider.flag(for: id))
                        Text(ClockZone.humanize(identifier: id))
                        Spacer()
                        Text(id).font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 240)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 420, height: 400)
    }
}
