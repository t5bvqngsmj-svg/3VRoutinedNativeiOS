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
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                HStack(alignment: .center) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .glassCard(cornerRadius: 12)
                    .buttonStyle(.plain)

                    Text(routine.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                    Spacer()

                    Button(action: {
                        showingStatistics = true
                    }) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .glassCard(cornerRadius: 12)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .zIndex(3)
                
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
                            .allowsHitTesting(false)
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
                            .allowsHitTesting(false)
                    }
                    #endif
                }

                if showSummaryCard {
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
                                if settingsManager.settings.showTaskTargets {
                                    Text(Translations.string("task_target", language: settingsManager.settings.language) + ": " + task.formattedTargetTime)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                }
                            }
                            
                            Spacer()
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
            RunningRoutineView(routine: routine) {
                showingRunningRoutine = false
                            presentationMode.wrappedValue.dismiss()
            }
            .environmentObject(settingsManager)
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

    private var showSummaryCard: Bool {
        routine.isScheduled || settingsManager.settings.showTaskTargets
    }
}
