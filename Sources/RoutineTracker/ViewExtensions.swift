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
                            Color.white.opacity(0.22),
                            lineWidth: 1.0
                        )
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
        }
    }
}

struct LiquidIconCircleButtonStyle: ButtonStyle {
    var accent: Color
    var size: CGFloat = 36
    var prominent: Bool = false
    var glowMultiplier: Double = 1.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .foregroundStyle(accent.opacity(prominent ? 1 : 0.94))
            .background {
                GlassEffectContainer {
                    Circle()
                        .glassEffect(.regular, in: Circle())
                }
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(prominent ? 0.38 : 0.24), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .shadow(
                color: accent.opacity(
                    glowMultiplier * (configuration.isPressed
                    ? (prominent ? 0.34 : 0.22)
                    : (prominent ? 0.16 : 0.08))
                ),
                radius: configuration.isPressed ? 14 : 6,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct LiquidCapsuleButtonStyle: ButtonStyle {
    var accent: Color
    var prominent: Bool = false
    var height: CGFloat = 48
    var glowMultiplier: Double = 1.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .foregroundStyle(prominent ? accent : Color.white.opacity(0.86))
            .background {
                GlassEffectContainer {
                    Capsule(style: .continuous)
                        .glassEffect(.regular, in: Capsule(style: .continuous))
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(prominent ? 0.34 : 0.18), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .shadow(
                color: accent.opacity(
                    glowMultiplier * (configuration.isPressed
                    ? (prominent ? 0.30 : 0.12)
                    : (prominent ? 0.12 : 0.04))
                ),
                radius: configuration.isPressed ? 12 : 6,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == LiquidIconCircleButtonStyle {
    static func liquidIconCircle(accent: Color, size: CGFloat = 36, prominent: Bool = false, glowMultiplier: Double = 1.0) -> Self {
        .init(accent: accent, size: size, prominent: prominent, glowMultiplier: glowMultiplier)
    }
}

extension ButtonStyle where Self == LiquidCapsuleButtonStyle {
    static func liquidCapsule(accent: Color, prominent: Bool = false, height: CGFloat = 48, glowMultiplier: Double = 1.0) -> Self {
        .init(accent: accent, prominent: prominent, height: height, glowMultiplier: glowMultiplier)
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

// MARK: - Week Day Selector
struct WeekDaySelector: View {
    @Binding var selected: Set<Int>
    var accent: Color
    var isDarkMode: Bool

    // weekday integers follow Calendar convention: 1=Sun 2=Mon … 7=Sat
    private let days: [(label: String, weekday: Int)] = [
        ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7), ("S", 1)
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.weekday) { day in
                let isOn = selected.contains(day.weekday)
                Button {
                    withAnimation(.easeOut(duration: 0.14)) {
                        if isOn { selected.remove(day.weekday) }
                        else    { selected.insert(day.weekday) }
                    }
                } label: {
                    Text(day.label)
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .foregroundStyle(isOn ? accent : Color.white.opacity(0.55))
                }
                .background {
                    GlassEffectContainer {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .glassEffect(
                                isOn ? .regular.tint(accent.opacity(0.25)) : .regular,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isOn ? accent.opacity(0.55) : Color.white.opacity(0.18),
                            lineWidth: isOn ? 1.5 : 1
                        )
                )
                .shadow(
                    color: isOn ? accent.opacity(0.22) : .clear,
                    radius: 6, x: 0, y: 2
                )
                .animation(.easeOut(duration: 0.14), value: isOn)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}
