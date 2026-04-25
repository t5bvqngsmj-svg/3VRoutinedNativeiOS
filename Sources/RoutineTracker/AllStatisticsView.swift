import SwiftUI

struct AllStatisticsView: View {
    let routines: [Routine]
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode

    private struct RoutineStat: Identifiable {
        let id: String
        let name: String
        let completions: Int
        let bestTime: TimeInterval?
        let averageTime: TimeInterval?
    }

    @State private var stats: [RoutineStat] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OVERVIEW".uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.15)
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                    Text("Statistics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        if stats.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 48))
                                    .foregroundColor(settingsManager.settings.currentPalette.accentColor.opacity(0.5))
                                Text("No statistics yet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                Text("Complete a routine to see your stats here.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            let totalCompletions = stats.reduce(0) { $0 + $1.completions }
                            HStack(spacing: 12) {
                                summaryCard(
                                    value: "\(routines.count)",
                                    label: "Routines",
                                    icon: "list.bullet.rectangle"
                                )
                                summaryCard(
                                    value: "\(totalCompletions)",
                                    label: "Total Runs",
                                    icon: "checkmark.seal.fill"
                                )
                            }
                            .padding(.horizontal, 24)

                            ForEach(stats) { stat in
                                routineStatCard(stat)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)
                    .padding(.top, 8)
                }
            }
            .background(
                AppBackgroundView(settings: settingsManager.settings)
                    .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                        .padding(.top, 20)
                        .padding(.trailing, 24)
                    }
                    Spacer()
                }
            )
        }
        .onAppear { loadAllStats() }
    }

    @ViewBuilder
    private func summaryCard(value: String, label: String, icon: String) -> some View {
        let accent = settingsManager.settings.currentPalette.accentColor
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accent)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .glassCard(cornerRadius: 14)
    }

    @ViewBuilder
    private func routineStatCard(_ stat: RoutineStat) -> some View {
        let accent = settingsManager.settings.currentPalette.accentColor
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stat.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                Spacer()
                Text("\(stat.completions) runs")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accent)
            }

            HStack(spacing: 12) {
                if let best = stat.bestTime {
                    VStack(spacing: 4) {
                        Text("BEST")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        Text(formattedTime(best))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 10)
                }

                if let avg = stat.averageTime {
                    VStack(spacing: 4) {
                        Text("AVG")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        Text(formattedTime(avg))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 10)
                }

                if stat.bestTime == nil && stat.averageTime == nil {
                    Text("No runs recorded")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private func loadAllStats() {
        var result: [RoutineStat] = []
        for routine in routines {
            if let data = UserDefaults.standard.data(forKey: "statistics_\(routine.id)"),
               let decoded = try? JSONDecoder().decode(RoutineStatistics.self, from: data) {
                let times = decoded.completions.map { $0.totalTime }
                let best = times.min()
                let avg = times.isEmpty ? nil : times.reduce(0, +) / Double(times.count)
                result.append(RoutineStat(
                    id: routine.id.uuidString,
                    name: routine.name,
                    completions: decoded.completions.count,
                    bestTime: best,
                    averageTime: avg
                ))
            } else {
                result.append(RoutineStat(
                    id: routine.id.uuidString,
                    name: routine.name,
                    completions: 0,
                    bestTime: nil,
                    averageTime: nil
                ))
            }
        }
        stats = result.filter { $0.completions > 0 }
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
