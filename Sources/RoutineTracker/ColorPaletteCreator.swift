import SwiftUI

struct ColorPaletteCreator: View {
    @ObservedObject var settingsManager: SettingsManager
    var editingPalette: ThemePalette? = nil
    @Environment(\.presentationMode) var presentationMode
    
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
            _gradientEndColor = State(initialValue: p.backgroundGradientEnd ?? RGBColor(red: 0.2, green: 0.2, blue: 0.3))
        } else {
            _paletteName = State(initialValue: "Arctic Night")
            _textColor = State(initialValue: RGBColor(red: 1.0, green: 1.0, blue: 1.0))
            _backgroundColor = State(initialValue: RGBColor(red: 0.098, green: 0.098, blue: 0.098))
            _accentColor = State(initialValue: RGBColor(red: 0.784, green: 0.961, blue: 1.0))
            _surfaceColor = State(initialValue: RGBColor(red: 0.149, green: 0.149, blue: 0.149))
            _useGradient = State(initialValue: false)
            _gradientEndColor = State(initialValue: RGBColor(red: 0.2, green: 0.2, blue: 0.3))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CREATE PALETTE".uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.15)
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        
                        Text("Create Custom Theme")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Palette Name".uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            
                            TextField("My Custom Theme", text: $paletteName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                .padding(12)
                                .glassCard(cornerRadius: 12)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Color Palette".uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                .padding(.horizontal, 24)
                            
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
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                            .padding(.horizontal, 24)
                        }
                        
                        // Color Picker
                        if !activeColorField.isEmpty {
                            let binding = colorBinding(for: activeColorField)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color Picker".uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                    .padding(.horizontal, 24)

                                InlineColorPicker(color: binding)
                                    .id(activeColorField)
                                    .padding(12)
                                    .glassCard(cornerRadius: 12)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview".uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    if useGradient {
                                        LinearGradient(
                                            colors: [backgroundColor.asColor, gradientEndColor.asColor],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    } else {
                                        backgroundColor.asColor
                                    }
                                }
                                .frame(height: 80)
                                .cornerRadius(8)
                                
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(textColor.asColor)
                                        .frame(height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(accentColor.asColor)
                                        .frame(height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(surfaceColor.asColor)
                                        .frame(height: 20)
                                }
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 20)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
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
            .navigationBarHidden(true)
        }
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
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary(isDarkMode: isDarkMode))
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 6)
                .fill(color.asColor)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .padding(12)
        .background(isActive ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(10)
        .onTapGesture(perform: onTap)
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
            // 2D saturation/brightness canvas
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
                    // Thumb
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

            // Hue rainbow slider
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

            // Hex preview row
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.asColor)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(hexString)
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

    private var hexString: String {
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
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
