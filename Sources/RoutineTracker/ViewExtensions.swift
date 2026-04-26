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
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.30),
                                    Color.white.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                )
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

    func appBackground(settings: AppSettings, paletteOverride: ThemePalette?) -> some View {
        self.background(
            AppBackgroundView(settings: settings, paletteOverride: paletteOverride)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Shared App Background View
struct AppBackgroundView: View {
    let settings: AppSettings
    var paletteOverride: ThemePalette? = nil

    private var palette: ThemePalette {
        paletteOverride ?? settings.currentPalette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient

            Rectangle()
                .fill(Color.black.opacity(settings.isDarkMode ? 0.16 : 0.04))

            Circle()
                .fill(palette.accentColor.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -90, y: -140)

            Circle()
                .fill(palette.surfaceColor.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 110, y: 220)

            Circle()
                .fill(palette.accentColor.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 70)
                .offset(x: 130, y: 40)
        }
    }
}
