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
    @Environment(\.presentationMode) var presentationMode
    @State private var paletteCreatorMode: PaletteCreatorMode? = nil
    @State private var selectedLanguage: String
    @State private var selectedTheme: String
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _selectedLanguage = State(initialValue: settingsManager.settings.language)
        _selectedTheme = State(initialValue: settingsManager.settings.themeColor == "teal" ? "spaceGrey" : settingsManager.settings.themeColor)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Translations.string("settings", language: settingsManager.settings.language).uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.15)
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        
                        Text(Translations.string("settings", language: settingsManager.settings.language))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(Translations.string("appearance", language: settingsManager.settings.language).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            
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
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(Translations.string("language", language: settingsManager.settings.language).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 16))
                                    .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)
                                Text(Translations.string("language", language: settingsManager.settings.language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { selectedLanguage },
                                    set: { newVal in
                                        selectedLanguage = newVal
                                        settingsManager.settings.language = newVal
                                        settingsManager.save()
                                    }
                                )) {
                                    ForEach(Language.allCases, id: \.self) { lang in
                                        Text(lang.displayName).tag(lang.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)
                            }
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(Translations.string("save_mode", language: settingsManager.settings.language).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                            HStack {
                                Image(systemName: "tray.and.arrow.down")
                                    .font(.system(size: 16))
                                    .foregroundColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)
                                Text(Translations.string("save_mode", language: settingsManager.settings.language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingsManager.settings.saveMode },
                                    set: { newVal in
                                        settingsManager.settings.saveMode = newVal
                                        settingsManager.save()
                                    }
                                )) {
                                    ForEach(["statistics", "leaderboard"], id: \.self) { mode in
                                        Text(Translations.string(mode, language: settingsManager.settings.language)).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(ThemeColors.getColors(for: selectedTheme, customPalettes: settingsManager.settings.customPalettes).accentColor)
                            }
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }

                HStack {
                    Button(action: {
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
                .padding(.vertical, 20)
            }
            .appBackground(settings: settingsManager.settings)
            .ignoresSafeArea()
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
