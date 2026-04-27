import SwiftUI

struct StatisticsView: View {
    let routine: Routine
    @State private var statistics: RoutineStatistics?
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.liquidIconCircle(accent: settingsManager.settings.currentPalette.accentColor))

                Text(routine.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                if let stats = statistics {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("\(stats.completions.count)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            
                            Text(Translations.string("completions", language: settingsManager.settings.language))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .glassCard(cornerRadius: 12)
                        .padding(.horizontal, 24)

                            HStack(spacing: 12) {
                                if let fastest = stats.fastestTime {
                                    VStack(spacing: 8) {
                                        Text(Translations.string("fastest", language: settingsManager.settings.language))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                        
                                        Text(formattedTime(fastest))
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .glassCard(cornerRadius: 12)
                                }

                                if let slowest = stats.slowestTime {
                                    VStack(spacing: 8) {
                                        Text(Translations.string("slowest", language: settingsManager.settings.language))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                        
                                        Text(formattedTime(slowest))
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(settingsManager.settings.currentPalette.accentColor.opacity(0.7))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .glassCard(cornerRadius: 12)
                                }
                            }
                            .padding(.horizontal, 24)

                            if let average = stats.averageTime {
                                VStack(spacing: 8) {
                                    Text(Translations.string("average", language: settingsManager.settings.language))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                    Text(formattedTime(average))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .glassCard(cornerRadius: 12)
                                .padding(.horizontal, 24)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text(Translations.string("recent_completions", language: settingsManager.settings.language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 8) {
                                    ForEach(stats.completions.reversed().prefix(5), id: \.id) { completion in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(formattedTime(completion.totalTime))
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                                
                                                Text(formattedDate(completion.completedDate))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .glassCard(cornerRadius: 10)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor.opacity(0.6))
                        
                        Text(Translations.string("no_statistics_available", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
        .onAppear {
            loadStatistics()
        }
    }
    
    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: "statistics_\(routine.id)"),
           let decoded = try? JSONDecoder().decode(RoutineStatistics.self, from: data) {
            statistics = decoded
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}
