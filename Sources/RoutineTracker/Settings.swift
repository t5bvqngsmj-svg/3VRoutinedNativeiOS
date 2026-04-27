import Foundation

struct UserAccount: Codable {
    var id = UUID()
    var username: String
    var createdDate: Date = Date()
}

struct RoutineStatistics: Codable {
    var routineId: UUID
    var routineName: String
    var completions: [CompletionRecord]
    
    var fastestTime: TimeInterval? {
        completions.map { $0.totalTime }.min()
    }
    
    var slowestTime: TimeInterval? {
        completions.map { $0.totalTime }.max()
    }
    
    var averageTime: TimeInterval? {
        guard !completions.isEmpty else { return nil }
        return completions.map { $0.totalTime }.reduce(0, +) / Double(completions.count)
    }
}

struct CompletionRecord: Codable {
    var id = UUID()
    var totalTime: TimeInterval
    var completedDate: Date = Date()
}

struct AppSettings: Codable {
    var dataVersion: Int = 1
    var currentUser: UserAccount?
    var isDarkMode: Bool = true
    var language: String = "en"
    var themeColor: String = "spaceGrey"
    var saveMode: String = "statistics"
    var customPalettes: [ThemePalette] = []
    var useThemeBackground: Bool = true
    var showTaskTargets: Bool = false
    var colorInputMode: String = "both"
    var countdownBetaEnabled: Bool = false
    var countdownMilestoneNotificationsEnabled: Bool = true
    var adaptiveReminderEngineEnabled: Bool = false
    var quickCreateBetaEnabled: Bool = false
    var betasEnabled: Bool = true

    var currentPalette: ThemePalette {
        let resolvedTheme = ThemeColors.canonicalThemeId(for: themeColor)
        return ThemeColors.getColors(for: resolvedTheme, customPalettes: customPalettes)
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dataVersion = (try? c.decode(Int.self, forKey: .dataVersion)) ?? 1
        currentUser = try? c.decodeIfPresent(UserAccount.self, forKey: .currentUser)
        isDarkMode = (try? c.decode(Bool.self, forKey: .isDarkMode)) ?? true
        language = (try? c.decode(String.self, forKey: .language)) ?? "en"
        themeColor = (try? c.decode(String.self, forKey: .themeColor)) ?? "spaceGrey"
        let decodedSaveMode = (try? c.decode(String.self, forKey: .saveMode)) ?? "statistics"
        saveMode = ["statistics", "off"].contains(decodedSaveMode) ? decodedSaveMode : "statistics"
        customPalettes = (try? c.decode([ThemePalette].self, forKey: .customPalettes)) ?? []
        useThemeBackground = (try? c.decode(Bool.self, forKey: .useThemeBackground)) ?? true
        showTaskTargets = (try? c.decode(Bool.self, forKey: .showTaskTargets)) ?? false
            _ = (try? c.decode(String.self, forKey: .colorInputMode)) ?? "both"
        colorInputMode = "both"
        countdownBetaEnabled = (try? c.decode(Bool.self, forKey: .countdownBetaEnabled)) ?? false
        countdownMilestoneNotificationsEnabled = (try? c.decode(Bool.self, forKey: .countdownMilestoneNotificationsEnabled)) ?? true
        adaptiveReminderEngineEnabled = (try? c.decode(Bool.self, forKey: .adaptiveReminderEngineEnabled)) ?? false
        quickCreateBetaEnabled = (try? c.decode(Bool.self, forKey: .quickCreateBetaEnabled)) ?? false
        betasEnabled = (try? c.decode(Bool.self, forKey: .betasEnabled)) ?? true
    }
}

class SettingsManager: ObservableObject {
    @Published var settings: AppSettings
    @Published var resetToken: UUID = UUID()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
}
