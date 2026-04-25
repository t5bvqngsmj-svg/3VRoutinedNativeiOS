import SwiftUI

struct RGBColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    
    var asColor: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    init(red: Double, green: Double, blue: Double) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.red = try container.decode(Double.self, forKey: .red)
        self.green = try container.decode(Double.self, forKey: .green)
        self.blue = try container.decode(Double.self, forKey: .blue)
    }
    
    enum CodingKeys: String, CodingKey {
        case red, green, blue
    }
}

struct ThemePalette: Identifiable, Codable {
    let id: String
    let name: String
    let text: RGBColor
    let background: RGBColor
    let accent: RGBColor
    let surface: RGBColor
    var backgroundGradientEnd: RGBColor?

    var swatches: [Color] {
        [accent.asColor, surface.asColor, background.asColor]
    }

    var primary: Color { text.asColor }
    var secondary: Color { background.asColor }
    var accentColor: Color { accent.asColor }
    var surfaceColor: Color { surface.asColor }
    var backgroundColor: Color { background.asColor }
    var textColor: Color { text.asColor }

    /// Returns a gradient from background to backgroundGradientEnd (or solid if no gradient end)
    var backgroundGradient: LinearGradient {
        let end = backgroundGradientEnd?.asColor ?? background.asColor
        return LinearGradient(
            colors: [background.asColor, end],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var hasGradient: Bool { backgroundGradientEnd != nil }

    enum CodingKeys: String, CodingKey {
        case id, name, text, background, accent, surface, backgroundGradientEnd
    }
}

struct ThemeColors {
    static func getColors(for theme: String, customPalettes: [ThemePalette] = []) -> ThemePalette {
        palette(for: theme, customPalettes: customPalettes)
    }

    // Only dark palettes are defined. Light palettes are auto-converted by the system if needed.
    static let palettes: [ThemePalette] = [
        ThemePalette(
            id: "spaceGrey",
            name: "Space Grey",
            text: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
            background: RGBColor(red: 0.06, green: 0.06, blue: 0.07),
            accent: RGBColor(red: 0.65, green: 0.65, blue: 0.68),
            surface: RGBColor(red: 0.11, green: 0.11, blue: 0.12),
            backgroundGradientEnd: RGBColor(red: 0.10, green: 0.10, blue: 0.11)
        ),
        ThemePalette(
            id: "purple",
            name: "Purple",
            text: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
            background: RGBColor(red: 0.07, green: 0.05, blue: 0.14),
            accent: RGBColor(red: 0.70, green: 0.50, blue: 0.90),
            surface: RGBColor(red: 0.14, green: 0.09, blue: 0.24),
            backgroundGradientEnd: RGBColor(red: 0.18, green: 0.08, blue: 0.30)
        ),
        ThemePalette(
            id: "orange",
            name: "Orange",
            text: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
            background: RGBColor(red: 0.10, green: 0.08, blue: 0.06),
            accent: RGBColor(red: 0.96, green: 0.64, blue: 0.35),
            surface: RGBColor(red: 0.18, green: 0.14, blue: 0.11),
            backgroundGradientEnd: RGBColor(red: 0.22, green: 0.14, blue: 0.06)
        )
    ]

    static var availableThemes: [String] {
        palettes.map { $0.id }
    }

    static func palette(for theme: String, customPalettes: [ThemePalette] = []) -> ThemePalette {
        let resolvedTheme = (theme == "teal") ? "spaceGrey" : theme

        // Check custom palettes first
        if let custom = customPalettes.first(where: { $0.id == resolvedTheme }) {
            return custom
        }
        // Fall back to built-in palettes
        return palettes.first { $0.id == resolvedTheme } ?? palettes[0]
    }

    static func displayName(for theme: String, customPalettes: [ThemePalette] = []) -> String {
        palette(for: theme, customPalettes: customPalettes).name
    }
    
    /// Create a custom palette with RGB values (0...1)
    static func createCustomPalette(
        id: String,
        name: String,
        text: RGBColor,
        background: RGBColor,
        accent: RGBColor,
        surface: RGBColor,
        backgroundGradientEnd: RGBColor? = nil
    ) -> ThemePalette {
        ThemePalette(id: id, name: name, text: text, background: background, accent: accent, surface: surface, backgroundGradientEnd: backgroundGradientEnd)
    }
}

struct AppColors {
    static func appBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.04, green: 0.12, blue: 0.15) : Color(red: 0.96, green: 0.97, blue: 0.98)
    }
    
    static func appGradientStart(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.04, green: 0.12, blue: 0.15) : Color(red: 0.94, green: 0.96, blue: 0.98)
    }
    
    static func appGradientEnd(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.07, green: 0.24, blue: 0.27) : Color(red: 0.89, green: 0.93, blue: 0.96)
    }
    
    static func surface(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.04, green: 0.12, blue: 0.15).opacity(0.8) : Color.white.opacity(0.9)
    }
    
    static func panel(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(red: 0.07, green: 0.18, blue: 0.22).opacity(0.8) : Color.white.opacity(0.95)
    }
    
    static func textPrimary(isDarkMode: Bool) -> Color {
        isDarkMode ? .white : .black
    }
    
    static func textSecondary(isDarkMode: Bool) -> Color {
        isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.65)
    }
}

