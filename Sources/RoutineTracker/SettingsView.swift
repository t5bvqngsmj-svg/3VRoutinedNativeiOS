import SwiftUI

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
    @Environment(\.dismiss) private var dismiss
    @State private var paletteCreatorMode: PaletteCreatorMode? = nil
    @State private var selectedLanguage: String
    @State private var selectedTheme: String
    @State private var showingLanguageDialog = false
    @State private var showingColorInputDialog = false
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _selectedLanguage = State(initialValue: settingsManager.settings.language)
        _selectedTheme = State(initialValue: ThemeColors.canonicalThemeId(for: settingsManager.settings.themeColor))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Translations.string("settings", language: settingsManager.settings.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: settingsManager.settings.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)
                            
                            Text(Translations.string("dark_mode", language: settingsManager.settings.language))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { settingsManager.settings.isDarkMode },
                                set: {
                                    settingsManager.settings.isDarkMode = $0
                                    settingsManager.save()
                                }
                            ))
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)

                        themeSelectionView()

                        selectionRow(
                            icon: "globe",
                            title: Translations.string("language", language: settingsManager.settings.language),
                            value: Language(rawValue: selectedLanguage)?.displayName ?? selectedLanguage,
                            action: { showingLanguageDialog = true }
                        )

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

                        VStack(alignment: .leading, spacing: 10) {
                            selectionRow(
                                icon: "tray.and.arrow.down",
                                title: Translations.string("save_mode", language: settingsManager.settings.language),
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
                                icon: "paintpalette",
                                title: Translations.string("color_input", language: settingsManager.settings.language),
                                value: Translations.string(settingsManager.settings.colorInputMode, language: settingsManager.settings.language),
                                action: { showingColorInputDialog = true }
                            )

                            Text(Translations.string("color_input_description", language: settingsManager.settings.language))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }

            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text(Translations.string("all_routines", language: settingsManager.settings.language))
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
        .confirmationDialog(Translations.string("color_input", language: settingsManager.settings.language), isPresented: $showingColorInputDialog, titleVisibility: .visible) {
            Button(Translations.string("picker", language: settingsManager.settings.language)) {
                settingsManager.settings.colorInputMode = "picker"
                settingsManager.save()
            }
            Button(Translations.string("hex", language: settingsManager.settings.language)) {
                settingsManager.settings.colorInputMode = "hex"
                settingsManager.save()
            }
            Button(Translations.string("both", language: settingsManager.settings.language)) {
                settingsManager.settings.colorInputMode = "both"
                settingsManager.save()
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
                }
                .buttonStyle(.plain)
                .glassCard(cornerRadius: 12)
            }
        }
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
                selectedTheme = palette.id
                settingsManager.settings.themeColor = palette.id
                settingsManager.save()
            }

            HStack(spacing: 0) {
                Button {
                    deleteCustomPalette(id: palette.id)
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red.opacity(0.85))
                        .padding(5)
                }
                Button {
                    paletteCreatorMode = .edit(palette)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(5)
                }
            }
            .padding(2)
        }
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
            .padding(4)
            .glassCard(cornerRadius: 14)
        }
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
