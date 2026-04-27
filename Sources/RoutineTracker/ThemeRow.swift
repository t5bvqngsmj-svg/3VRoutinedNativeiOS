import SwiftUI

struct ThemeRow: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingPaletteCreator = false
    
    var body: some View {
        HStack(spacing: 18) {
            ForEach(ThemeColors.palettes.prefix(3), id: \.id) { palette in
                Button(action: {
                    settingsManager.settings.themeColor = palette.id
                    settingsManager.save()
                }) {
                    VStack {
                        Circle()
                            .fill(palette.accent.asColor)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(settingsManager.settings.themeColor == palette.id ? Color.white : Color.clear, lineWidth: 3)
                            )
                        Text(palette.name)
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    }
                }
                .buttonStyle(.glass)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            // Customizable 4th slot
            Button(action: {
                showingPaletteCreator = true
            }) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                }
            }
            .buttonStyle(.glass)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .sheet(isPresented: $showingPaletteCreator) {
                ColorPaletteCreator(settingsManager: settingsManager)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .glassCard(cornerRadius: 18)
    }
}

// Glassmorphic BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
