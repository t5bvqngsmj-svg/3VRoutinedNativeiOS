import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct RoutineDetailView: View {
    let routine: Routine
    @State private var showingRunningRoutine = false
    @State private var showingStatistics = false
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                HStack(alignment: .center) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Translations.string("routine_manager", language: settingsManager.settings.language))
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.15)
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        Text(routine.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    }

                    Spacer()

                    if settingsManager.settings.saveMode == "statistics" {
                        Button(action: { showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                    }

                    Button(action: {
                        SharePresenter.share(text: routineShareText)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                if let imageData = routine.imageData {
                    #if os(iOS)
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(18)
                            .padding(.horizontal, 24)
                    }
                    #else
                    if let image = NSImage(data: imageData) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(18)
                            .padding(.horizontal, 24)
                    }
                    #endif
                }

                HStack {
                    Image(systemName: routine.isScheduled ? "calendar.circle" : "target")
                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                    Text(scheduleSummary)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    Spacer()
                }
                .padding(12)
                .glassCard(cornerRadius: 10)
                .padding(.horizontal, 24)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(routine.tasks.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 12) {
                            VStack(alignment: .center, spacing: 0) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            }
                            .frame(width: 30, height: 30)
                            .glassCard(cornerRadius: 6)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                Text(Translations.string("task_target", language: settingsManager.settings.language) + ": " + task.formattedTargetTime)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20))
                                .foregroundColor(settingsManager.settings.currentPalette.primary)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            VStack(spacing: 12) {
                Button(action: {
                    showingRunningRoutine = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text(Translations.string("start_routine", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingRunningRoutine) {
            RunningRoutineView(routine: routine).environmentObject(settingsManager)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(routine: routine, settingsManager: settingsManager)
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var scheduleSummary: String {
        if routine.isScheduled, let scheduledTime = routine.scheduledTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let lang = settingsManager.settings.language
            return "\(Translations.string("scheduled", language: lang)): \(formatter.string(from: scheduledTime))"
        }
        return Translations.string("target", language: settingsManager.settings.language) + ": \(formattedTime(routine.totalTargetTime))"
    }

    private var routineShareText: String {
        let lang = settingsManager.settings.language
        let tasksText = routine.tasks.map { "- \($0.name) (\(formattedTime($0.targetTime)))" }.joined(separator: "\n")
        return "\(Translations.string("routine_label", language: lang)): \(routine.name)\n\(scheduleSummary)\n\(Translations.string("tasks_label", language: lang)):\n\(tasksText)"
    }
}
