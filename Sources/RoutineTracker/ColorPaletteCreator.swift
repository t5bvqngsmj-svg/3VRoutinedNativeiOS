import SwiftUI

struct ColorPaletteCreator: View {
    @ObservedObject var settingsManager: SettingsManager
    var editingPalette: ThemePalette? = nil
    @Environment(\.presentationMode) private var presentationMode

    @State private var paletteName: String
    @State private var textColor: RGBColor
    @State private var backgroundColor: RGBColor
    @State private var accentColor: RGBColor
    @State private var surfaceColor: RGBColor
    @State private var useGradient: Bool
    @State private var gradientEndColor: RGBColor

    @State private var activeColorField: String = "accent"

    init(settingsManager: SettingsManager, editingPalette: ThemePalette? = nil) {
        self.settingsManager = settingsManager
        self.editingPalette = editingPalette
        if let p = editingPalette {
            _paletteName = State(initialValue: p.name)
            _textColor = State(initialValue: p.text)
            _backgroundColor = State(initialValue: p.background)
            _accentColor = State(initialValue: p.accent)
            _surfaceColor = State(initialValue: p.surface)
            _useGradient = State(initialValue: p.backgroundGradientEnd != nil)
            _gradientEndColor = State(initialValue: p.backgroundGradientEnd ?? RGBColor(red: 0.18, green: 0.22, blue: 0.34))
        } else {
            _paletteName = State(initialValue: "Night Drive")
            _textColor = State(initialValue: RGBColor(red: 0.98, green: 0.99, blue: 1.0))
            _backgroundColor = State(initialValue: RGBColor(red: 0.03, green: 0.03, blue: 0.08))
            _accentColor = State(initialValue: RGBColor(red: 0.34, green: 0.93, blue: 0.89))
            _surfaceColor = State(initialValue: RGBColor(red: 0.12, green: 0.18, blue: 0.30))
            _useGradient = State(initialValue: true)
            _gradientEndColor = State(initialValue: RGBColor(red: 0.20, green: 0.05, blue: 0.26))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(editingPalette == nil ? "Create Custom Theme" : "Edit Theme")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("My Custom Theme", text: $paletteName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Colors")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                        VStack(spacing: 12) {
                            ColorPickerRow(
                                label: "Background",
                                color: $backgroundColor,
                                isDarkMode: settingsManager.settings.isDarkMode,
                                isActive: activeColorField == "background",
                                onTap: { activeColorField = "background" }
                            )

                            HStack {
                                Text("Background Gradient")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                Spacer()
                                Toggle("", isOn: $useGradient)
                                    .tint(accentColor.asColor)
                            }
                            .padding(12)
                            .glassCard(cornerRadius: 12)

                            if useGradient {
                                ColorPickerRow(
                                    label: "Gradient End",
                                    color: $gradientEndColor,
                                    isDarkMode: settingsManager.settings.isDarkMode,
                                    isActive: activeColorField == "gradientEnd",
                                    onTap: { activeColorField = "gradientEnd" }
                                )
                            }

                            ColorPickerRow(
                                label: "Text",
                                color: $textColor,
                                isDarkMode: settingsManager.settings.isDarkMode,
                                isActive: activeColorField == "text",
                                onTap: { activeColorField = "text" }
                            )

                            ColorPickerRow(
                                label: "Accent",
                                color: $accentColor,
                                isDarkMode: settingsManager.settings.isDarkMode,
                                isActive: activeColorField == "accent",
                                onTap: { activeColorField = "accent" }
                            )

                            ColorPickerRow(
                                label: "Surface",
                                color: $surfaceColor,
                                isDarkMode: settingsManager.settings.isDarkMode,
                                isActive: activeColorField == "surface",
                                onTap: { activeColorField = "surface" }
                            )
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 24)

                    if showsPicker {
                        let binding = colorBinding(for: activeColorField)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Visual Picker")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                            InlineColorPicker(color: binding)
                                .id(activeColorField)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16)
                        .padding(.horizontal, 24)
                    }

                    if showsHexInputs {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hex Codes")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                            HexColorFieldRow(label: "Background", color: $backgroundColor)

                            if useGradient {
                                HexColorFieldRow(label: "Gradient End", color: $gradientEndColor)
                            }

                            HexColorFieldRow(label: "Text", color: $textColor)
                            HexColorFieldRow(label: "Accent", color: $accentColor)
                            HexColorFieldRow(label: "Surface", color: $surfaceColor)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16)
                        .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))

                        ZStack {
                            previewBackground
                                .frame(height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(paletteName.isEmpty ? "My Custom Theme" : paletteName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(textColor.asColor)
                                    Spacer()
                                    Circle()
                                        .fill(accentColor.asColor)
                                        .frame(width: 18, height: 18)
                                }

                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white.opacity(0.32), lineWidth: 1)
                                    )
                                    .overlay(
                                        VStack(alignment: .leading, spacing: 8) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(textColor.asColor.opacity(0.92))
                                                .frame(width: 110, height: 12)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(accentColor.asColor)
                                                .frame(width: 76, height: 12)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                    )
                                    .frame(height: 88)

                                HStack(spacing: 8) {
                                    ForEach(previewSwatches, id: \.self) { shade in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(shade)
                                            .frame(height: 22)
                                    }
                                }
                            }
                            .padding(18)
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)

                Button(action: savePalette) {
                    Text("Save Palette")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(20)
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
    }

    private var showsPicker: Bool {
        settingsManager.settings.colorInputMode != "hex"
    }

    private var showsHexInputs: Bool {
        settingsManager.settings.colorInputMode != "picker"
    }

    @ViewBuilder
    private var previewBackground: some View {
        if useGradient {
            LinearGradient(
                colors: [backgroundColor.asColor, gradientEndColor.asColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            backgroundColor.asColor
        }
    }

    private var previewSwatches: [Color] {
        [accentColor.asColor, surfaceColor.asColor, backgroundColor.asColor]
    }

    private func colorBinding(for fieldName: String) -> Binding<RGBColor> {
        switch fieldName {
        case "background":
            return $backgroundColor
        case "text":
            return $textColor
        case "surface":
            return $surfaceColor
        case "gradientEnd":
            return $gradientEndColor
        default:
            return $accentColor
        }
    }

    private func savePalette() {
        let paletteId = editingPalette?.id ?? "custom_\(UUID().uuidString.prefix(8))"
        let savedPalette = ThemePalette(
            id: paletteId,
            name: paletteName.isEmpty ? "My Custom Theme" : paletteName,
            text: textColor,
            background: backgroundColor,
            accent: accentColor,
            surface: surfaceColor,
            backgroundGradientEnd: useGradient ? gradientEndColor : nil
        )

        if let idx = settingsManager.settings.customPalettes.firstIndex(where: { $0.id == paletteId }) {
            settingsManager.settings.customPalettes[idx] = savedPalette
        } else {
            settingsManager.settings.customPalettes.append(savedPalette)
        }
        settingsManager.settings.themeColor = paletteId
        settingsManager.save()

        presentationMode.wrappedValue.dismiss()
    }
}

struct ColorPickerRow: View {
    let label: String
    @Binding var color: RGBColor
    let isDarkMode: Bool
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDarkMode: isDarkMode))
                Text(color.hexString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary(isDarkMode: isDarkMode))
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(color.asColor)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.white : Color.white.opacity(0.18), lineWidth: isActive ? 2 : 1)
                )
        }
        .padding(12)
        .background(isActive ? Color.white.opacity(0.08) : Color.clear)
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct HexColorFieldRow: View {
    let label: String
    @Binding var color: RGBColor
    @State private var input: String = ""

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.asColor)
                .frame(width: 28, height: 28)

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            TextField("#FFFFFF", text: $input)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .onSubmit(commit)
                .onChange(of: input) { _, newValue in
                    if let parsed = RGBColor(hex: newValue) {
                        color = parsed
                    }
                }
                .frame(width: 112)
        }
        .padding(.vertical, 6)
        .onAppear {
            input = color.hexString
        }
        .onChange(of: color) { _, newValue in
            if input != newValue.hexString {
                input = newValue.hexString
            }
        }
    }

    private func commit() {
        if let parsed = RGBColor(hex: input) {
            color = parsed
            input = parsed.hexString
        } else {
            input = color.hexString
        }
    }
}

struct InlineColorPicker: View {
    @Binding var color: RGBColor

    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1

    private var hueColors: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 12.0).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        } + [Color(hue: 1, saturation: 1, brightness: 1)]
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Color(hue: hue, saturation: 1, brightness: 1)
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top, endPoint: .bottom
                    )
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(color.asColor))
                        .frame(width: 22, height: 22)
                        .shadow(radius: 2)
                        .position(
                            x: min(max(saturation * geo.size.width, 11), geo.size.width - 11),
                            y: min(max((1 - brightness) * geo.size.height, 11), geo.size.height - 11)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            saturation = min(max(value.location.x / geo.size.width, 0), 1)
                            brightness = min(max(1 - value.location.y / geo.size.height, 0), 1)
                            commitColor()
                        }
                )
            }
            .frame(height: 200)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(colors: hueColors, startPoint: .leading, endPoint: .trailing)
                        .clipShape(Capsule())
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(Color(hue: hue, saturation: 1, brightness: 1)))
                        .frame(width: 28, height: 28)
                        .shadow(radius: 2)
                        .offset(x: hue * max(geo.size.width - 28, 0))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hue = min(max(value.location.x / geo.size.width, 0), 1)
                            commitColor()
                        }
                )
            }
            .frame(height: 28)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.asColor)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(color.hexString)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(String(format: "R%.0f  G%.0f  B%.0f", color.red * 255, color.green * 255, color.blue * 255))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
        }
        .onAppear { syncFromColor() }
        .onChange(of: color) { _, _ in syncFromColor() }
    }

    private func syncFromColor() {
        let ui = UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, bv: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &bv, alpha: &a)
        hue = Double(h)
        saturation = Double(s)
        brightness = Double(bv)
    }

    private func commitColor() {
        let ui = UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        color = RGBColor(red: Double(r), green: Double(g), blue: Double(b))
    }
}

#Preview {
    ColorPaletteCreator(settingsManager: SettingsManager())
}
