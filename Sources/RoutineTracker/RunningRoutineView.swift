import SwiftUI

struct RunningRoutineView: View {
    let routine: Routine
    var onExitToHome: (() -> Void)? = nil
    @State private var currentTaskIndex = 0
    @State private var taskStartTime = Date()
    @State private var totalTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isCompleted = false
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        ZStack {
            AppBackgroundView(settings: settingsManager.settings)
                .ignoresSafeArea()

            if isCompleted {
                CompletionView(routine: routine, totalTime: totalTime) {
                    onExitToHome?()
                }
                .environmentObject(settingsManager)
            } else {
                VStack(spacing: 30) {
                    Text(routine.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 30)

                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text(Translations.string("current_task", language: settingsManager.settings.language))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            
                            Text(routine.tasks[currentTaskIndex].name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(settingsManager.settings.currentPalette.primary)
                        }
                        
                        VStack(spacing: 12) {
                            VStack(spacing: 8) {
                                Text(Translations.string("elapsed_time", language: settingsManager.settings.language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                
                                Text(formattedTime(elapsedTime))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .glassCard(cornerRadius: 16)

                            if settingsManager.settings.showTaskTargets && routine.tasks[currentTaskIndex].targetTime > 0 {
                                VStack(spacing: 10) {
                                    VStack(spacing: 6) {
                                        Text(Translations.string("task_target", language: settingsManager.settings.language))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                        Text(formattedTime(routine.tasks[currentTaskIndex].targetTime))
                                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                    }
                                    Text(elapsedTime <= routine.tasks[currentTaskIndex].targetTime ? Translations.string("on_track", language: settingsManager.settings.language) : Translations.string("behind_schedule", language: settingsManager.settings.language))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(elapsedTime <= routine.tasks[currentTaskIndex].targetTime ? Color.green.opacity(0.92) : Color.orange.opacity(0.92))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(18)
                                .glassCard(cornerRadius: 16)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ForEach(0..<routine.tasks.count, id: \.self) { index in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(index < currentTaskIndex ? settingsManager.settings.currentPalette.primary : (index == currentTaskIndex ? settingsManager.settings.currentPalette.accentColor : AppColors.surface(isDarkMode: settingsManager.settings.isDarkMode).opacity(0.35)))
                                        .frame(width: 10, height: 10)
                                    Text("\(index + 1)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    Button(action: nextTask) {
                        HStack {
                            Image(systemName: currentTaskIndex == routine.tasks.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            Text(currentTaskIndex == routine.tasks.count - 1
                                 ? Translations.string("finish_routine", language: settingsManager.settings.language)
                                 : Translations.string("next_task", language: settingsManager.settings.language))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            if routine.tasks.isEmpty {
                isCompleted = true
            } else {
                startTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        taskStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(taskStartTime)
        }
    }

    private func nextTask() {
        totalTime += elapsedTime
        if currentTaskIndex < routine.tasks.count - 1 {
            currentTaskIndex += 1
            elapsedTime = 0
            startTimer()
        } else {
            completeRoutine()
        }
    }

    private func completeRoutine() {
        totalTime += elapsedTime
        isCompleted = true
        timer?.invalidate()
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
