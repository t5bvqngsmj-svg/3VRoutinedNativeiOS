import SwiftUI

struct GlassNavbar: View {
    @ObservedObject var settingsManager: SettingsManager
    var homeAction: () -> Void
    var createAction: () -> Void
    var statsAction: () -> Void

    var body: some View {
        let accent = settingsManager.settings.currentPalette.accentColor

        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(accent.opacity(0.06))

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            HStack(spacing: 0) {
                Button(action: homeAction) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                }

                Button(action: createAction) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 54, height: 54)
                        Circle()
                            .strokeBorder(accent.opacity(0.45), lineWidth: 1.5)
                            .frame(width: 54, height: 54)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(accent)
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: statsAction) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
        .frame(height: 76)
        .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 10)
        .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 3)
    }
}
