import SwiftUI

enum RoutineSheetMode: Identifiable {
    case create
    case edit(Routine)
    case settings
    case stats

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let r): return r.id.uuidString
        case .settings: return "settings"
        case .stats: return "stats"
        }
    }
}

struct ContentView: View {
    @State private var routines: [Routine] = []
    @State private var sheetMode: RoutineSheetMode? = nil
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppBackgroundView(settings: settingsManager.settings)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Text(Translations.string("routine_tracker", language: settingsManager.settings.language))
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                        Spacer()
                        Button(action: {
                            sheetMode = .stats
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                        Button(action: {
                            sheetMode = .settings
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    ScrollView {
                        VStack(spacing: 12) {
                            Color.clear.frame(height: 4)
                            if routines.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(settingsManager.settings.currentPalette.primary.opacity(0.6))
                                    Text(Translations.string("no_routines", language: settingsManager.settings.language))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                ForEach(routines) { routine in
                                    NavigationLink(destination: RoutineDetailView(routine: routine).environmentObject(settingsManager)) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            if let imageData = routine.imageData,
                                               let image = UIImage(data: imageData) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 110)
                                                    .frame(maxWidth: .infinity)
                                                    .clipped()
                                                    .cornerRadius(16)
                                            }
                                            HStack {
                                                Text(routine.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                                Spacer()
                                                Text("\(routine.tasks.count) \(Translations.string("tasks", language: settingsManager.settings.language))")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                            }
                                            if routine.isScheduled || settingsManager.settings.showTaskTargets {
                                                Text(routine.targetSummary)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                            }
                                            HStack(spacing: 6) {
                                                ForEach(routine.tasks.prefix(3), id: \.id) { task in
                                                    Text(task.name)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                                        .lineLimit(1)
                                                }
                                                if routine.tasks.count > 3 {
                                                    Text("+\(routine.tasks.count - 3)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                                                }
                                            }
                                        }
                                        .padding()
                                        .glassCard(cornerRadius: 16)
                                    }
                                    .contextMenu {
                                        Button {
                                            sheetMode = .edit(routine)
                                        } label: {
                                            Label("Edit Routine", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            deleteRoutine(id: routine.id)
                                        } label: {
                                            Label("Delete Routine", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .mask(
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black.opacity(0.3), location: 0.25),
                                    .init(color: .black.opacity(0.8), location: 0.6),
                                    .init(color: .black, location: 1)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 90)
                            Color.black
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .edgesIgnoringSafeArea(.bottom)

                let accent = settingsManager.settings.currentPalette.accentColor
                Button(action: { sheetMode = .create }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())
                .padding(.bottom, 8)
            }
        }
        .sheet(item: $sheetMode) { mode in
            switch mode {
            case .create:
                CreateRoutineView(routines: $routines).environmentObject(settingsManager)
            case .edit(let routine):
                CreateRoutineView(routines: $routines, editingRoutine: routine) { updated in
                    if let idx = routines.firstIndex(where: { $0.id == updated.id }) {
                        routines[idx] = updated
                    }
                }
                .environmentObject(settingsManager)
            case .settings:
                SettingsView(settingsManager: settingsManager)
            case .stats:
                AllStatisticsView(routines: routines, settingsManager: settingsManager)
            }
        }
        .onAppear {
            loadRoutines()
        }
        .onChange(of: routines) { _, _ in
            saveRoutines()
        }
    }

    private func deleteRoutine(id: UUID) {
        routines.removeAll { $0.id == id }
    }

    private func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: "routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
            NotificationsManager.syncNotifications(for: decoded)
        }
    }

    private func saveRoutines() {
        if let data = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(data, forKey: "routines")
        }
    }
}
