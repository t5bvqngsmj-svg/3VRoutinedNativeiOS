import SwiftUI

struct CreateCountdownView: View {
    @Binding var countdowns: [CountdownItem]
    var editingCountdown: CountdownItem? = nil
    var onUpdate: ((CountdownItem) -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var countdownName = ""
    @State private var countdownDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var includeTime = false
    @State private var reminderSelection: Set<CountdownReminder> = [.dayOf]
    @State private var countdownImage: PlatformImage?
    @State private var showingImagePicker = false

    init(
        countdowns: Binding<[CountdownItem]>,
        editingCountdown: CountdownItem? = nil,
        onUpdate: ((CountdownItem) -> Void)? = nil
    ) {
        self._countdowns = countdowns
        self.editingCountdown = editingCountdown
        self.onUpdate = onUpdate

        if let countdown = editingCountdown {
            _countdownName = State(initialValue: countdown.name)
            _countdownDate = State(initialValue: countdown.targetDate)
            _includeTime = State(initialValue: countdown.includesTime)
            _reminderSelection = State(initialValue: Set(countdown.reminders))
            if let data = countdown.imageData {
                #if os(iOS)
                _countdownImage = State(initialValue: UIImage(data: data))
                #else
                _countdownImage = State(initialValue: NSImage(data: data))
                #endif
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(
                    editingCountdown == nil
                    ? Translations.string("create_countdown", language: settingsManager.settings.language)
                    : Translations.string("edit_countdown", language: settingsManager.settings.language)
                )
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                Spacer()

                HStack(spacing: 10) {
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: countdownImage == nil ? "photo.badge.plus" : "photo.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .buttonStyle(.liquidIconCircle(accent: settingsManager.settings.currentPalette.accentColor, size: 42, prominent: true))
                    .accessibilityLabel(Translations.string("upload_image", language: settingsManager.settings.language))

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .buttonStyle(.liquidIconCircle(accent: settingsManager.settings.currentPalette.accentColor))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Text(Translations.string("countdown_setup_subtitle", language: settingsManager.settings.language))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 6)

            ScrollView {
                VStack(spacing: 16) {
                    if let image = countdownImage {
                        #if os(iOS)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(16)
                        #else
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(16)
                        #endif
                    }

                    VStack(spacing: 12) {
                        TextField(Translations.string("countdown_name", language: settingsManager.settings.language), text: $countdownName)
                            .customStyle(isDarkMode: settingsManager.settings.isDarkMode)
                        DatePicker(
                            Translations.string("countdown_target_date", language: settingsManager.settings.language),
                            selection: $countdownDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 12)

                        Toggle(isOn: $includeTime) {
                            Text(Translations.string("include_time", language: settingsManager.settings.language))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: settingsManager.settings.currentPalette.accentColor))
                        .padding(.horizontal, 12)

                        if includeTime {
                            DatePicker(
                                Translations.string("countdown_time", language: settingsManager.settings.language),
                                selection: $countdownDate,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(Translations.string("countdown_notifications", language: settingsManager.settings.language))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                        Menu {
                            ForEach(CountdownReminder.allCases) { reminder in
                                Button {
                                    toggleReminder(reminder)
                                } label: {
                                    Label(
                                        Translations.string(reminder.translationKey, language: settingsManager.settings.language),
                                        systemImage: reminderSelection.contains(reminder) ? "checkmark.circle.fill" : "circle"
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                Text(reminderSummary)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .glassCard(cornerRadius: 12)
                        }
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            VStack(spacing: 12) {
                Button(action: saveCountdown) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(Translations.string("save", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .disabled(countdownName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text(Translations.string("cancel", language: settingsManager.settings.language))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $countdownImage)
        }
    }

    private var reminderSummary: String {
        CountdownReminder.allCases
            .filter { reminderSelection.contains($0) }
            .map { Translations.string($0.translationKey, language: settingsManager.settings.language) }
            .joined(separator: ", ")
    }

    private func toggleReminder(_ reminder: CountdownReminder) {
        if reminderSelection.contains(reminder) {
            reminderSelection.remove(reminder)
        } else {
            reminderSelection.insert(reminder)
        }
        if reminderSelection.isEmpty {
            reminderSelection.insert(.dayOf)
        }
    }

    private func saveCountdown() {
        let trimmedName = countdownName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let finalDate = mergedTargetDate()
        let imageData: Data?
        if let image = countdownImage {
            #if os(iOS)
            imageData = image.jpegData(compressionQuality: 0.75)
            #else
            imageData = image.tiffRepresentation
            #endif
        } else {
            imageData = nil
        }

        let countdown = CountdownItem(
            id: editingCountdown?.id ?? UUID(),
            name: trimmedName,
            targetDate: finalDate,
            includesTime: includeTime,
            imageData: imageData,
            reminders: Array(reminderSelection).sorted { $0.rawValue < $1.rawValue },
            createdAt: editingCountdown?.createdAt ?? Date(),
            isPinned: editingCountdown?.isPinned ?? false
        )

        if let onUpdate {
            onUpdate(countdown)
        } else {
            countdowns.append(countdown)
        }

        if let existing = editingCountdown {
            NotificationsManager.cancelNotifications(for: existing)
        }
        NotificationsManager.scheduleNotifications(
            for: countdown,
            includeMilestones: settingsManager.settings.countdownMilestoneNotificationsEnabled
        )
        presentationMode.wrappedValue.dismiss()
    }

    private func mergedTargetDate() -> Date {
        let calendar = Calendar.current
        if includeTime {
            return countdownDate
        }

        let day = calendar.startOfDay(for: countdownDate)
        return calendar.date(byAdding: .hour, value: 9, to: day) ?? day
    }
}
