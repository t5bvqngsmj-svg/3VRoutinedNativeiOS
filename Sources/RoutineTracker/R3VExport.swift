import Foundation

// MARK: - R3V Backup Format
// Version 1 of the Routined export format.
// A .r3v file is JSON-encoded R3VExport containing settings, routines,
// countdowns, and per-routine statistics.

struct R3VExport: Codable {
    var version: Int = 1
    var exportDate: Date = Date()
    var settings: AppSettings
    var routines: [Routine]
    var countdowns: [CountdownItem]
    var statistics: [String: RoutineStatistics]

    // MARK: - Collect current data from UserDefaults
    static func collect(
        settings: AppSettings,
        routines: [Routine],
        countdowns: [CountdownItem]
    ) -> R3VExport {
        var stats: [String: RoutineStatistics] = [:]
        for routine in routines {
            if let data = UserDefaults.standard.data(forKey: "statistics_\(routine.id)"),
               let stat = try? JSONDecoder().decode(RoutineStatistics.self, from: data) {
                stats[routine.id.uuidString] = stat
            }
        }
        return R3VExport(
            settings: settings,
            routines: routines,
            countdowns: countdowns,
            statistics: stats
        )
    }

    // MARK: - Write to a temp file and return the URL
    func writeToTempFile() throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = formatter.string(from: exportDate)
        let filename = "Routined_\(dateString).r3v"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Restore from a .r3v file URL
    static func restore(from url: URL, settingsManager: SettingsManager) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(R3VExport.self, from: data)

        // Cancel all existing notifications before overwriting
        if let existingData = UserDefaults.standard.data(forKey: "routines"),
           let existing = try? JSONDecoder().decode([Routine].self, from: existingData) {
            for r in existing { NotificationsManager.cancelNotifications(for: r) }
        }
        if let existingData = UserDefaults.standard.data(forKey: "countdowns"),
           let existing = try? JSONDecoder().decode([CountdownItem].self, from: existingData) {
            for c in existing { NotificationsManager.cancelNotifications(for: c) }
        }

        let encoder = JSONEncoder()

        // Write routines
        if let encoded = try? encoder.encode(export.routines) {
            UserDefaults.standard.set(encoded, forKey: "routines")
        }

        // Write countdowns
        if let encoded = try? encoder.encode(export.countdowns) {
            UserDefaults.standard.set(encoded, forKey: "countdowns")
        }

        // Write per-routine statistics
        for (id, stat) in export.statistics {
            if let encoded = try? encoder.encode(stat) {
                UserDefaults.standard.set(encoded, forKey: "statistics_\(id)")
            }
        }

        // Restore settings
        settingsManager.settings = export.settings
        settingsManager.save()

        // Trigger ContentView reload
        settingsManager.resetToken = UUID()

        // Reschedule notifications
        NotificationsManager.syncNotifications(
            for: export.routines,
            useAdaptive: export.settings.adaptiveReminderEngineEnabled
        )
        NotificationsManager.syncCountdownNotifications(
            for: export.countdowns,
            includeMilestones: export.settings.countdownMilestoneNotificationsEnabled
        )
    }
}
