import SwiftUI

private struct PenaltyItem: Identifiable {
    let id = UUID()
    let seconds: Int
}

@main
struct RoutineTrackerApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @State private var penaltyItem: PenaltyItem? = nil
    @Environment(\.scenePhase) var scenePhase

    private let penaltyKey = "lmPenalty"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.settings.isDarkMode ? .dark : .light)
                .onAppear {
                    NotificationsManager.configureForegroundPresentation()
                    NotificationsManager.requestAuthorization()
                    let saved = UserDefaults.standard.integer(forKey: penaltyKey)
                    if saved > 0 {
                        penaltyItem = PenaltyItem(seconds: saved)
                    }
                }
            .fullScreenCover(item: $penaltyItem) { item in
                LightModeErrorView(
                    initialCountdown: item.seconds,
                    onComplete: {
                        settingsManager.settings.isDarkMode = true
                        settingsManager.save()
                        UserDefaults.standard.set(0, forKey: penaltyKey)
                        exit(0)
                    }
                )
            }
            .onChange(of: settingsManager.settings.isDarkMode) { _, isDark in
                if !isDark {
                    let existing = UserDefaults.standard.integer(forKey: penaltyKey)
                    let penalty = existing > 0 ? existing : 30
                    UserDefaults.standard.set(penalty, forKey: penaltyKey)
                    penaltyItem = PenaltyItem(seconds: penalty)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                let hadPenalty = UserDefaults.standard.integer(forKey: penaltyKey) > 0
                if phase == .background && hadPenalty {
                    let current = UserDefaults.standard.integer(forKey: penaltyKey)
                    let updated = current + 30
                    UserDefaults.standard.set(updated, forKey: penaltyKey)
                    UserDefaults.standard.synchronize()
                } else if phase == .active {
                    let saved = UserDefaults.standard.integer(forKey: penaltyKey)
                    if saved > 0 {
                        penaltyItem = PenaltyItem(seconds: saved)
                    }
                }
            }
        }
    }
}
