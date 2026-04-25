import SwiftUI

struct CompletionView: View {
    let routine: Routine
    let totalTime: TimeInterval
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(settingsManager.settings.currentPalette.primary)

                VStack(spacing: 8) {
                    Text(Translations.string("routine_completed", language: settingsManager.settings.language).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.15)
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    
                    Text(Translations.string("great_job", language: settingsManager.settings.language))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                }
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(Translations.string("total_time", language: settingsManager.settings.language))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    
                    Text(formattedTime(totalTime))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .glassCard(cornerRadius: 16)

                Text(getCompliment())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassCard(cornerRadius: 16)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    SharePresenter.share(text: scoreShareText)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(Translations.string("share_score", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)

                Button(action: {
                    saveCompletion()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text(Translations.string("back_to_home", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func getCompliment() -> String {
        let lang = settingsManager.settings.language
        let compliments: [String]
        switch lang {
        case "nl":
            compliments = [
                "Geweldig gedaan! Je hebt je routine voltooid.",
                "Fantastisch werk! Blijf zo doorgaan.",
                "Je bent geweldig! Routine afgerond.",
                "Uitstekend! Geniet van je dag."
            ]
        case "de":
            compliments = [
                "Großartig! Du hast deine Routine abgeschlossen.",
                "Fantastische Arbeit! Weiter so.",
                "Du bist super! Routine erledigt.",
                "Ausgezeichnet! Genieße deinen Tag."
            ]
        case "fr":
            compliments = [
                "Excellent ! Tu as terminé ta routine.",
                "Travail fantastique ! Continue comme ça.",
                "Tu es incroyable ! Routine accomplie.",
                "Parfait ! Profite de ta journée."
            ]
        default:
            compliments = [
                "Great job! You completed your routine.",
                "Fantastic work! Keep it up.",
                "You're crushing it! Routine done.",
                "Excellent! Enjoy the rest of your day."
            ]
        }
        return compliments.randomElement() ?? "Great job!"
    }
    
    private func saveCompletion() {
        guard settingsManager.settings.saveMode == "statistics" else { return }
        
        let completion = CompletionRecord(totalTime: totalTime)
        var stats = loadStatistics()
        stats.completions.append(completion)
        
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "statistics_\(routine.id)")
        }
    }
    
    private func loadStatistics() -> RoutineStatistics {
        if let data = UserDefaults.standard.data(forKey: "statistics_\(routine.id)"),
           let decoded = try? JSONDecoder().decode(RoutineStatistics.self, from: data) {
            return decoded
        }
        return RoutineStatistics(routineId: routine.id, routineName: routine.name, completions: [])
    }

    private var scoreShareText: String {
        Translations.string("share_score_message", language: settingsManager.settings.language)
            .replacingOccurrences(of: "{routine}", with: routine.name)
            .replacingOccurrences(of: "{time}", with: formattedTime(totalTime))
    }
}
