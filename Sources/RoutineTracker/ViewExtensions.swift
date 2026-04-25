import SwiftUI

// MARK: - Glass Card Modifier
// GlassEffectContainer is required by iOS 26 for correct multi-panel glass compositing.
// Without it, multiple .glassEffect() panels on the same screen can't composite correctly
// and render as flat/opaque. The system UIMenu dropdown gets this container for free.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        GlassEffectContainer {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func backdrop() -> some View {
        self.glassCard(cornerRadius: 16)
    }

    func appBackground(settings: AppSettings) -> some View {
        self.background(
            AppBackgroundView(settings: settings)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Shared App Background View
struct AppBackgroundView: View {
    let settings: AppSettings

    private var palette: ThemePalette {
        ThemeColors.getColors(for: settings.themeColor, customPalettes: settings.customPalettes)
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient

            Circle()
                .fill(palette.accentColor.opacity(0.6))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -90, y: -140)

            Circle()
                .fill(palette.surfaceColor.opacity(0.5))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 110, y: 220)

            Circle()
                .fill(palette.accentColor.opacity(0.35))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: 130, y: 40)
        }
    }
}
