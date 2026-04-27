import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#endif

enum PaletteCreatorMode: Identifiable {
    case create
    case edit(ThemePalette)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let p): return p.id
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.isPresented) private var isPresented
    @State private var paletteCreatorMode: PaletteCreatorMode? = nil
    @State private var selectedLanguage: String
    @State private var selectedTheme: String
    @State private var showingLanguageDialog = false
    @State private var longPressedPaletteId: String? = nil
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingNotificationCount: Int = 0
    @State private var nextNotificationDate: Date? = nil
    @State private var nextNotificationId: String? = nil
    @State private var showResetConfirmation = false
    @State private var showImportFilePicker = false
    @State private var importResultMessage: String? = nil

    private var accentColor: Color {
        ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor
    }
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _selectedLanguage = State(initialValue: settingsManager.settings.language)
        _selectedTheme = State(initialValue: ThemeColors.canonicalThemeId(for: settingsManager.settings.themeColor))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text(Translations.string("settings", language: settingsManager.settings.language))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    Spacer()
                    if isPresented {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .buttonStyle(.liquidIconCircle(accent: accentColor, glowMultiplier: 0.2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        Color.clear.frame(height: 8)

                        sectionPanel("General") {
                            HStack {
                                Image(systemName: settingsManager.settings.isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(accentColor)

                                Text(Translations.string("dark_mode", language: settingsManager.settings.language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { settingsManager.settings.isDarkMode },
                                    set: { newValue in
                                        settingsManager.settings.isDarkMode = newValue
                                        settingsManager.save()
                                        if !newValue {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                ))
                            }
                            .padding(12)
                            .glassCard(cornerRadius: 12)

                            selectionRow(
                                icon: "globe",
                                title: Translations.string("language", language: settingsManager.settings.language),
                                value: Language(rawValue: selectedLanguage)?.displayName ?? selectedLanguage,
                                action: { showingLanguageDialog = true }
                            )
                        }

                        sectionPanel("Appearance") {
                            themeSelectionView()
                        }

                        sectionPanel("Tracking") {
                            VStack(alignment: .leading, spacing: 10) {
                                selectionRow(
                                    icon: "chart.bar.fill",
                                    title: Translations.string("statistics", language: settingsManager.settings.language),
                                    trailing: AnyView(
                                        Toggle("", isOn: Binding(
                                            get: { settingsManager.settings.saveMode == "statistics" },
                                            set: {
                                                settingsManager.settings.saveMode = $0 ? "statistics" : "off"
                                                settingsManager.save()
                                            }
                                        ))
                                    )
                                )

                                Text(saveModeDescription)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .padding(.horizontal, 4)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                selectionRow(
                                    icon: "target",
                                    title: Translations.string("task_targets", language: settingsManager.settings.language),
                                    trailing: AnyView(
                                        Toggle("", isOn: Binding(
                                            get: { settingsManager.settings.showTaskTargets },
                                            set: {
                                                settingsManager.settings.showTaskTargets = $0
                                                settingsManager.save()
                                            }
                                        ))
                                    )
                                )

                                Text(Translations.string("task_targets_description", language: settingsManager.settings.language))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .padding(.horizontal, 4)
                            }
                        }

                        sectionPanel("Notifications") {
                            notificationHealthView
                        }

                        sectionPanel(
                            "Betas",
                            tone: .danger,
                            trailing: AnyView(
                                Toggle("", isOn: Binding(
                                    get: { settingsManager.settings.betasEnabled },
                                    set: { enabled in
                                        settingsManager.settings.betasEnabled = enabled
                                        if !enabled {
                                            settingsManager.settings.quickCreateBetaEnabled = false
                                            settingsManager.settings.adaptiveReminderEngineEnabled = false
                                            settingsManager.settings.countdownBetaEnabled = false
                                            settingsManager.settings.countdownMilestoneNotificationsEnabled = false
                                        }
                                        settingsManager.save()
                                        resyncRoutineNotifications()
                                    }
                                ))
                                .scaleEffect(0.9)
                            )
                        ) {
                            betaToggleRow(
                                icon: "plus.rectangle.on.folder",
                                title: "Quick Create Composer",
                                description: "Enables the inline quick create panel from the dock plus button.",
                                isOn: Binding(
                                    get: { settingsManager.settings.quickCreateBetaEnabled },
                                    set: {
                                        settingsManager.settings.quickCreateBetaEnabled = $0
                                        settingsManager.save()
                                    }
                                )
                            )

                            betaToggleRow(
                                icon: "brain.head.profile",
                                title: "Adaptive Reminder Engine",
                                description: "Learns when you actually complete routines and shifts reminder times automatically.",
                                isOn: Binding(
                                    get: { settingsManager.settings.adaptiveReminderEngineEnabled },
                                    set: {
                                        settingsManager.settings.adaptiveReminderEngineEnabled = $0
                                        settingsManager.save()
                                        resyncRoutineNotifications()
                                    }
                                )
                            )

                            betaToggleRow(
                                icon: "hourglass",
                                title: Translations.string("beta_countdown_mode", language: settingsManager.settings.language),
                                description: Translations.string("beta_countdown_mode_description", language: settingsManager.settings.language),
                                isOn: Binding(
                                    get: { settingsManager.settings.countdownBetaEnabled },
                                    set: {
                                        settingsManager.settings.countdownBetaEnabled = $0
                                        settingsManager.save()
                                    }
                                )
                            )

                            if settingsManager.settings.countdownBetaEnabled {
                                betaToggleRow(
                                    icon: "flag.checkered.2.crossed",
                                    title: "Countdown milestones",
                                    description: "Schedules milestone reminders at 75%, 50%, and 25% progress for each countdown.",
                                    isOn: Binding(
                                        get: { settingsManager.settings.countdownMilestoneNotificationsEnabled },
                                        set: {
                                            settingsManager.settings.countdownMilestoneNotificationsEnabled = $0
                                            settingsManager.save()
                                        }
                                    )
                                )
                            }
                        }
                        .opacity(settingsManager.settings.betasEnabled ? 1 : 0.46)

                        sectionPanel("Danger Zone", tone: .danger) {
                            Button(action: performExport) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export to .R3V")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .buttonStyle(.liquidCapsule(accent: accentColor, height: 44, glowMultiplier: 0.12))

                            Button(action: { showImportFilePicker = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import .R3V")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .buttonStyle(.liquidCapsule(accent: accentColor, height: 44, glowMultiplier: 0.12))

                            Button(action: {
                                withAnimation(.easeOut(duration: 0.16)) {
                                    showResetConfirmation = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                    Text("Reset Routined")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .buttonStyle(.liquidCapsule(accent: .red, prominent: true, height: 44, glowMultiplier: 0.18))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }

            if showResetConfirmation {
                Color.black.opacity(0.34)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.16)) {
                            showResetConfirmation = false
                        }
                    }

                VStack(spacing: 14) {
                    Text("Reset Routined")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                    Text("This will erase routines, countdowns, statistics, and settings. This action cannot be undone.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        Button(action: {
                            performHardReset()
                        }) {
                            Text("Reset Everything")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .buttonStyle(.liquidCapsule(accent: .red, prominent: true, height: 42, glowMultiplier: 0.18))

                        Button(action: {
                            withAnimation(.easeOut(duration: 0.16)) {
                                showResetConfirmation = false
                            }
                        }) {
                            Text(Translations.string("cancel", language: settingsManager.settings.language))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .buttonStyle(.liquidCapsule(accent: accentColor, height: 40, glowMultiplier: 0.12))
                    }
                }
                .padding(18)
                .glassCard(cornerRadius: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
        .confirmationDialog(Translations.string("language", language: settingsManager.settings.language), isPresented: $showingLanguageDialog, titleVisibility: .visible) {
            ForEach(Language.allCases, id: \.self) { lang in
                Button(lang.displayName) {
                    selectedLanguage = lang.rawValue
                    settingsManager.settings.language = lang.rawValue
                    settingsManager.save()
                }
            }
        }
        .sheet(item: $paletteCreatorMode) { mode in
            switch mode {
            case .create:
                ColorPaletteCreator(settingsManager: settingsManager)
            case .edit(let palette):
                ColorPaletteCreator(settingsManager: settingsManager, editingPalette: palette)
            }
        }
        .onAppear {
            refreshNotificationHealth()
        }
        .fileImporter(
            isPresented: $showImportFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                performImport(from: url)
            case .failure:
                importResultMessage = "Could not access the selected file."
            }
        }
        .alert("Import Result", isPresented: Binding(
            get: { importResultMessage != nil },
            set: { if !$0 { importResultMessage = nil } }
        )) {
            Button("OK") { importResultMessage = nil }
        } message: {
            if let msg = importResultMessage { Text(msg) }
        }
    }

    private func deleteCustomPalette(id: String) {
        settingsManager.settings.customPalettes.removeAll { $0.id == id }
        if settingsManager.settings.themeColor == id {
            settingsManager.settings.themeColor = "spaceGrey"
            selectedTheme = "spaceGrey"
        }
        settingsManager.save()
    }

    @ViewBuilder
    private func themeSelectionView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Translations.string("theme", language: settingsManager.settings.language))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(ThemeColors.availableThemes, id: \.self) { theme in
                    themeOptionView(for: theme)
                }

                ForEach(settingsManager.settings.customPalettes, id: \.id) { palette in
                    customPaletteOptionView(palette)
                }

                createThemeButton()
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }

    private func selectionRow(icon: String, title: String, value: String? = nil, trailing: AnyView? = nil, action: @escaping () -> Void = {}) -> some View {
        Group {
            if let trailing {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)

                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                    Spacer()

                    trailing
                }
                .padding(12)
                .glassCard(cornerRadius: 12)
            } else {
                Button(action: action) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)

                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                        Spacer()

                        if let value {
                            Text(value)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        }
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private enum SectionTone {
        case normal
        case danger
    }

    private func sectionPanel<Content: View>(
        _ title: String,
        tone: SectionTone = .normal,
        trailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(
                        tone == .danger
                        ? Color.red.opacity(0.9)
                        : AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode)
                    )
                    .tracking(0.4)
                Spacer()
                trailing
            }

            VStack(spacing: 12) {
                content()
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    tone == .danger ? Color.red.opacity(0.28) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private func betaToggleRow(icon: String, title: String, description: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            selectionRow(
                icon: icon,
                title: title,
                trailing: AnyView(
                    Toggle("", isOn: isOn)
                        .scaleEffect(0.92)
                )
            )

            Text(description)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                .padding(.horizontal, 4)
        }
        .padding(.leading, 12)
    }

    private var saveModeDescription: String {
        let key = settingsManager.settings.saveMode == "statistics"
            ? "save_mode_statistics_description"
            : "save_mode_off_description"
        return Translations.string(key, language: settingsManager.settings.language)
    }

    @ViewBuilder
    private func themeOptionView(for theme: String) -> some View {
        let colors = ThemeColors.getColors(for: theme, customPalettes: settingsManager.settings.customPalettes)
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(colors.swatches, id: \.self) { shade in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shade)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(8)
            .background(colors.backgroundColor.opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 2)
            )

            Text(ThemeColors.displayName(for: theme, customPalettes: settingsManager.settings.customPalettes).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
        }
        .frame(maxWidth: .infinity)
        .padding(4)
        .glassCard(cornerRadius: 14)
        .onTapGesture {
            selectedTheme = theme
            settingsManager.settings.themeColor = theme
            settingsManager.save()
        }
    }

    @ViewBuilder
    private func customPaletteOptionView(_ palette: ThemePalette) -> some View {
        let colors = ThemeColors.getColors(for: palette.id, customPalettes: settingsManager.settings.customPalettes)
        let isLongPressed = longPressedPaletteId == palette.id
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(colors.swatches, id: \.self) { shade in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shade)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(8)
                .background(colors.backgroundColor.opacity(0.8))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedTheme == palette.id ? Color.white : Color.clear, lineWidth: 2)
                )

                Text(palette.name.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
            }
            .frame(maxWidth: .infinity)
            .padding(4)
            .glassCard(cornerRadius: 14)
            .onTapGesture {
                if isLongPressed {
                    longPressedPaletteId = nil
                } else {
                    selectedTheme = palette.id
                    settingsManager.settings.themeColor = palette.id
                    settingsManager.save()
                }
            }
            .onLongPressGesture {
                longPressedPaletteId = palette.id
            }

            if isLongPressed {
                HStack(spacing: 4) {
                    Button {
                        paletteCreatorMode = .edit(palette)
                        longPressedPaletteId = nil
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                    Button {
                        deleteCustomPalette(id: palette.id)
                        longPressedPaletteId = nil
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red.opacity(0.9))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                }
                .padding(6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isLongPressed)
    }

    @ViewBuilder
    private func createThemeButton() -> some View {
        Button(action: { paletteCreatorMode = .create }) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)

                Text("CREATE".uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var notificationHealthView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Notification Health", systemImage: "bell.badge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                Spacer()
                Button("Refresh") {
                    refreshNotificationHealth()
                }
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.glass)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 12) {
                Image(systemName: notificationAuthorizationStatus == .authorized || notificationAuthorizationStatus == .provisional ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(notificationAuthorizationStatus == .authorized || notificationAuthorizationStatus == .provisional ? .green.opacity(0.92) : .orange.opacity(0.9))

                Text("Permission: \(authorizationDescription)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                Spacer()
            }
            .padding(10)
            .glassCard(cornerRadius: 12)

            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)

                Text(nextNotificationDescription)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    .lineLimit(2)
                Spacer()
            }
            .padding(10)
            .glassCard(cornerRadius: 12)

            Text("Pending notifications: \(pendingNotificationCount)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                if notificationAuthorizationStatus == .notDetermined {
                    Button("Enable") {
                        requestNotificationAuthorization()
                    }
                    .buttonStyle(.liquidCapsule(accent: accentColor, prominent: true, height: 34, glowMultiplier: 0.2))
                }

                if notificationAuthorizationStatus == .denied {
                    Button("Open Settings") {
                        openSystemSettings()
                    }
                    .buttonStyle(.liquidCapsule(accent: accentColor, height: 34, glowMultiplier: 0.2))
                }
            }
        }
    }

    private func resyncRoutineNotifications() {
        guard let data = UserDefaults.standard.data(forKey: "routines"),
              let routines = try? JSONDecoder().decode([Routine].self, from: data) else { return }

        NotificationsManager.syncNotifications(
            for: routines,
            useAdaptive: settingsManager.settings.adaptiveReminderEngineEnabled
        )
    }

    private func performHardReset() {
        var routines: [Routine] = []
        var countdowns: [CountdownItem] = []

        if let data = UserDefaults.standard.data(forKey: "routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        }

        if let data = UserDefaults.standard.data(forKey: "countdowns"),
           let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data) {
            countdowns = decoded
        }

        for routine in routines {
            NotificationsManager.cancelNotifications(for: routine)
        }

        for countdown in countdowns {
            NotificationsManager.cancelNotifications(for: countdown)
        }

        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key == "routines"
                || key == "countdowns"
                || key == "appSettings"
                || key == "lmPenalty"
                || key == "adaptiveReminderProfiles"
                || key.hasPrefix("statistics_") {
                defaults.removeObject(forKey: key)
            }
        }

        settingsManager.settings = AppSettings()
        settingsManager.save()
        settingsManager.resetToken = UUID()

        selectedLanguage = settingsManager.settings.language
        selectedTheme = ThemeColors.canonicalThemeId(for: settingsManager.settings.themeColor)
        refreshNotificationHealth()

        withAnimation(.easeOut(duration: 0.16)) {
            showResetConfirmation = false
        }
    }

    private func performExport() {
        var routines: [Routine] = []
        var countdowns: [CountdownItem] = []
        if let data = UserDefaults.standard.data(forKey: "routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) { routines = decoded }
        if let data = UserDefaults.standard.data(forKey: "countdowns"),
           let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data) { countdowns = decoded }
        let export = R3VExport.collect(
            settings: settingsManager.settings,
            routines: routines,
            countdowns: countdowns
        )
        guard let url = try? export.writeToTempFile() else { return }
        SharePresenter.shareFile(url: url)
    }

    private func performImport(from url: URL) {
        guard url.pathExtension.lowercased() == "r3v" else {
            importResultMessage = "Invalid file. Please select a .R3V backup."
            return
        }
        do {
            try R3VExport.restore(from: url, settingsManager: settingsManager)
            selectedLanguage = settingsManager.settings.language
            selectedTheme = ThemeColors.canonicalThemeId(for: settingsManager.settings.themeColor)
            importResultMessage = "Backup imported successfully."
        } catch {
            importResultMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private var authorizationDescription: String {
        switch notificationAuthorizationStatus {
        case .authorized:
            return "Enabled"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not determined"
        @unknown default:
            return "Unknown"
        }
    }

    private var nextNotificationDescription: String {
        guard let nextDate = nextNotificationDate else {
            return "No upcoming scheduled notifications."
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateText = formatter.string(from: nextDate)

        if let nextNotificationId {
            return "Next alert: \(dateText) (\(nextNotificationId))"
        }
        return "Next alert: \(dateText)"
    }

    private func refreshNotificationHealth() {
        NotificationsManager.fetchNotificationHealth { snapshot in
            DispatchQueue.main.async {
                notificationAuthorizationStatus = snapshot.authorizationStatus
                pendingNotificationCount = snapshot.pendingCount
                nextNotificationDate = snapshot.nextTriggerDate
                nextNotificationId = snapshot.nextIdentifier
            }
        }
    }

    private func requestNotificationAuthorization() {
        NotificationsManager.requestAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            refreshNotificationHealth()
        }
    }

    private func openSystemSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

struct AccountCreationView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var username = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Translations.string("create_account", language: settingsManager.settings.language).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.15)
                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                
                Text(Translations.string("create_account", language: settingsManager.settings.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(spacing: 16) {
                TextField(Translations.string("username", language: settingsManager.settings.language), text: $username)
                    .customStyle(isDarkMode: settingsManager.settings.isDarkMode)
            }
            
            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    if !username.isEmpty {
                        settingsManager.settings.currentUser = UserAccount(username: username)
                        settingsManager.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(Translations.string("save", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .disabled(username.isEmpty)

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(Translations.string("cancel", language: settingsManager.settings.language))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
    }
}
