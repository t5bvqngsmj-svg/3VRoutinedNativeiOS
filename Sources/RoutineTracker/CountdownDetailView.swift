import SwiftUI

struct CountdownDetailView: View {
    let countdown: CountdownItem

    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let imageData = countdown.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(18)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(countdown.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                    Text("\(Translations.string("ends", language: settingsManager.settings.language)): \(formattedTargetDate)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard(cornerRadius: 16)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Translations.string("remaining", language: settingsManager.settings.language))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                        Text(remainingText(now: context.date))
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(Translations.string("countdown_notifications", language: settingsManager.settings.language))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                    HStack(spacing: 8) {
                        ForEach(countdown.reminders, id: \.id) { reminder in
                            Text(Translations.string(reminder.translationKey, language: settingsManager.settings.language))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .glassCard(cornerRadius: 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard(cornerRadius: 16)

                if settingsManager.settings.countdownMilestoneNotificationsEnabled && !milestoneRows.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Milestones")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                        ForEach(milestoneRows, id: \.label) { milestone in
                            HStack {
                                Text(milestone.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                Spacer()
                                Text(milestone.dateText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            }
                            .padding(10)
                            .glassCard(cornerRadius: 12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(settings: settingsManager.settings)
    }

    private var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = countdown.includesTime ? .short : .none
        return formatter.string(from: countdown.targetDate)
    }

    private func remainingText(now: Date) -> String {
        let diff = Int(countdown.targetDate.timeIntervalSince(now))
        if diff <= 0 {
            return Translations.string("ended", language: settingsManager.settings.language)
        }

        let days = diff / 86_400
        let hours = (diff % 86_400) / 3_600
        let minutes = (diff % 3_600) / 60
        let seconds = diff % 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        }
        return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
    }

    private var milestoneRows: [(label: String, dateText: String)] {
        let totalInterval = countdown.targetDate.timeIntervalSince(countdown.createdAt)
        guard totalInterval > 0 else { return [] }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let milestones: [(String, Double)] = [
            ("75% complete", 0.25),
            ("50% complete", 0.50),
            ("25% remaining", 0.75)
        ]

        return milestones.compactMap { milestone in
            let date = countdown.createdAt.addingTimeInterval(totalInterval * milestone.1)
            guard date < countdown.targetDate else { return nil }
            return (milestone.0, formatter.string(from: date))
        }
    }
}
