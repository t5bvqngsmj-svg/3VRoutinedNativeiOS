import SwiftUI
import UniformTypeIdentifiers

enum RoutineSheetMode: Identifiable {
    case create
    case createCountdown
    case edit(Routine)
    case editCountdown(CountdownItem)
    case settings
    case stats

    var id: String {
        switch self {
        case .create: return "create"
        case .createCountdown: return "create-countdown"
        case .edit(let r): return r.id.uuidString
        case .editCountdown(let c): return "edit-countdown-\(c.id.uuidString)"
        case .settings: return "settings"
        case .stats: return "stats"
        }
    }
}

private enum AppTab: Hashable {
    case routines
    case countdowns
    case create
    case stats
    case settings
}

struct ContentView: View {
    @State private var routines: [Routine] = []
    @State private var countdowns: [CountdownItem] = []
    @State private var sheetMode: RoutineSheetMode? = nil
    @State private var selectedTab: AppTab = .routines
    @State private var draggedRoutine: Routine?
    @State private var draggedCountdown: CountdownItem?
    @State private var showQuickAdd = false
    @State private var quickAddName = ""
    @State private var quickAddCountdownDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @FocusState private var quickAddFocused: Bool
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        let accent = settingsManager.settings.currentPalette.accentColor

        Group {
            if settingsManager.settings.countdownBetaEnabled {
                tabbedRoot(accent: accent)
            } else {
                singleRoot(accent: accent)
            }
        }
        .sheet(item: $sheetMode) { mode in
            switch mode {
            case .create:
                CreateRoutineView(routines: $routines).environmentObject(settingsManager)
            case .createCountdown:
                CreateCountdownView(countdowns: $countdowns).environmentObject(settingsManager)
            case .edit(let routine):
                CreateRoutineView(routines: $routines, editingRoutine: routine) { updated in
                    if let idx = routines.firstIndex(where: { $0.id == updated.id }) {
                        routines[idx] = updated
                    }
                }
                .environmentObject(settingsManager)
            case .editCountdown(let countdown):
                CreateCountdownView(countdowns: $countdowns, editingCountdown: countdown) { updated in
                    if let idx = countdowns.firstIndex(where: { $0.id == updated.id }) {
                        countdowns[idx] = updated
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
            loadCountdowns()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if settingsManager.settings.countdownBetaEnabled && newValue == .create {
                let fallbackTab: AppTab = oldValue == .create ? .routines : oldValue
                selectedTab = fallbackTab
                openFullComposer(for: fallbackTab)
                return
            }

            withAnimation(.easeOut(duration: 0.16)) { showQuickAdd = false }
            quickAddFocused = false
        }
        .onChange(of: settingsManager.settings.countdownBetaEnabled) { _, enabled in
            if !enabled && selectedTab == .countdowns { selectedTab = .routines }
        }
        .onChange(of: settingsManager.resetToken) { _, _ in
            loadRoutines()
            loadCountdowns()
        }
        .onChange(of: routines) { _, _ in
            saveRoutines()
        }
        .onChange(of: countdowns) { _, _ in
            saveCountdowns()
        }
        .onChange(of: settingsManager.settings.adaptiveReminderEngineEnabled) { _, _ in
            NotificationsManager.syncNotifications(
                for: routines,
                useAdaptive: settingsManager.settings.adaptiveReminderEngineEnabled
            )
        }
        .onChange(of: settingsManager.settings.quickCreateBetaEnabled) { _, enabled in
            if !enabled {
                withAnimation(.easeOut(duration: 0.16)) { showQuickAdd = false }
                quickAddFocused = false
            }
        }
    }

    @ViewBuilder
    private func tabbedRoot(accent: Color) -> some View {
        TabView(selection: $selectedTab) {
            Tab(
                Translations.string("routine_tracker", language: settingsManager.settings.language),
                systemImage: "list.bullet.rectangle.fill",
                value: AppTab.routines
            ) {
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(spacing: 12) {
                                Color.clear.frame(height: 4)
                                routinesListView
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }

                        if showQuickAdd {
                            quickAddPanel
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .zIndex(2)
                        }
                    }
                    .appBackground(settings: settingsManager.settings)
                    .navigationTitle(Translations.string("routine_tracker", language: settingsManager.settings.language))
                    .toolbarBackground(.hidden, for: .navigationBar)
                }
            }

            Tab(
                Translations.string("countdown_title", language: settingsManager.settings.language),
                systemImage: "hourglass.bottomhalf.filled",
                value: AppTab.countdowns
            ) {
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(spacing: 12) {
                                Color.clear.frame(height: 4)
                                countdownsListView
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }

                        if showQuickAdd {
                            quickAddPanel
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .zIndex(2)
                        }
                    }
                    .appBackground(settings: settingsManager.settings)
                    .navigationTitle(Translations.string("countdown_title", language: settingsManager.settings.language))
                    .toolbarBackground(.hidden, for: .navigationBar)
                }
            }

            Tab(
                Translations.string("create_new", language: settingsManager.settings.language),
                systemImage: "plus.circle.fill",
                value: AppTab.create
            ) {
                Color.clear
            }

            Tab(
                Translations.string("statistics", language: settingsManager.settings.language),
                systemImage: "chart.bar.fill",
                value: AppTab.stats
            ) {
                NavigationStack {
                    AllStatisticsView(routines: routines, settingsManager: settingsManager)
                        .appBackground(settings: settingsManager.settings)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }

            Tab(
                Translations.string("settings", language: settingsManager.settings.language),
                systemImage: "gear",
                value: AppTab.settings
            ) {
                NavigationStack {
                    SettingsView(settingsManager: settingsManager)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    @ViewBuilder
    private func singleRoot(accent: Color) -> some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 12) {
                        // Custom header — title + action buttons on the same row
                        HStack(alignment: .center) {
                            Text(Translations.string("routine_tracker", language: settingsManager.settings.language))
                                .font(.system(size: 34, weight: .bold))
                            Spacer()
                            topToolbarControls(accent: accent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        routinesListView
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                if showQuickAdd {
                    quickAddPanel
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }
            }
            .appBackground(settings: settingsManager.settings)
            .navigationBarHidden(true)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomCreateDock(accent: accent)
        }
    }

    private func topToolbarControls(accent: Color) -> some View {
        HStack(spacing: 10) {
            Button {
                openStatsSurface()
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(.liquidIconCircle(accent: accent))

            Button {
                openSettingsSurface()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(.liquidIconCircle(accent: accent))
        }
    }

    private func bottomCreateDock(accent: Color) -> some View {
        HStack {
            Spacer()

            Button {
                handleCreateTap()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(.liquidIconCircle(accent: accent, size: 50, prominent: true, glowMultiplier: 1.25))

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func openStatsSurface() {
        if settingsManager.settings.countdownBetaEnabled {
            selectedTab = .stats
        } else {
            sheetMode = .stats
        }
    }

    private func openSettingsSurface() {
        if settingsManager.settings.countdownBetaEnabled {
            selectedTab = .settings
        } else {
            sheetMode = .settings
        }
    }

    private var routinesListView: some View {
        Group {
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
                ForEach(sortedRoutines) { routine in
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
                                if routine.isPinned {
                                    Image(systemName: "pin.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                }
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
                    .onDrag {
                        draggedRoutine = routine
                        return NSItemProvider(object: routine.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: RoutineReorderDropDelegate(item: routine, routines: $routines, draggedRoutine: $draggedRoutine))
                    .contextMenu {
                        Button {
                            sheetMode = .edit(routine)
                        } label: {
                            Label("Edit Routine", systemImage: "pencil")
                        }
                        Button {
                            toggleRoutinePin(id: routine.id)
                        } label: {
                            Label(routine.isPinned ? "Unpin Routine" : "Pin Routine", systemImage: routine.isPinned ? "pin.slash" : "pin")
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
    }

    private var countdownsListView: some View {
        Group {
            if countdowns.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 48))
                        .foregroundColor(settingsManager.settings.currentPalette.primary.opacity(0.6))
                    Text(Translations.string("no_countdowns", language: settingsManager.settings.language))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(sortedCountdowns) { countdown in
                    NavigationLink(destination: CountdownDetailView(countdown: countdown).environmentObject(settingsManager)) {
                        VStack(alignment: .leading, spacing: 12) {
                            if let imageData = countdown.imageData,
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
                                Text(countdown.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                                if countdown.isPinned {
                                    Image(systemName: "pin.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                }
                                Spacer()
                                Text(formattedRemaining(for: countdown))
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(countdown.hasEnded ? AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode) : settingsManager.settings.currentPalette.accentColor)
                            }

                            Text("\(Translations.string("ends", language: settingsManager.settings.language)): \(formattedTargetDate(for: countdown))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                            HStack(spacing: 8) {
                                ForEach(countdown.reminders, id: \.id) { reminder in
                                    Text(Translations.string(reminder.translationKey, language: settingsManager.settings.language))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .glassCard(cornerRadius: 10)
                                }
                            }
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)
                    }
                    .onDrag {
                        draggedCountdown = countdown
                        return NSItemProvider(object: countdown.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: CountdownReorderDropDelegate(item: countdown, countdowns: $countdowns, draggedCountdown: $draggedCountdown))
                    .contextMenu {
                        Button {
                            sheetMode = .editCountdown(countdown)
                        } label: {
                            Label("Edit Countdown", systemImage: "pencil")
                        }
                        Button {
                            toggleCountdownPin(id: countdown.id)
                        } label: {
                            Label(countdown.isPinned ? "Unpin Countdown" : "Pin Countdown", systemImage: countdown.isPinned ? "pin.slash" : "pin")
                        }
                        Button(role: .destructive) {
                            deleteCountdown(id: countdown.id)
                        } label: {
                            Label("Delete Countdown", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var sortedRoutines: [Routine] {
        routines.enumerated().sorted { lhs, rhs in
            if lhs.element.isPinned != rhs.element.isPinned {
                return lhs.element.isPinned && !rhs.element.isPinned
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    private var sortedCountdowns: [CountdownItem] {
        countdowns.enumerated().sorted { lhs, rhs in
            if lhs.element.isPinned != rhs.element.isPinned {
                return lhs.element.isPinned && !rhs.element.isPinned
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    private func deleteRoutine(id: UUID) {
        routines.removeAll { $0.id == id }
    }

    private func toggleRoutinePin(id: UUID) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        var routine = routines.remove(at: index)
        routine.isPinned.toggle()

        if routine.isPinned {
            routines.insert(routine, at: 0)
        } else {
            let insertIndex = routines.firstIndex(where: { !$0.isPinned }) ?? routines.count
            routines.insert(routine, at: insertIndex)
        }
    }

    private func deleteCountdown(id: UUID) {
        guard let countdown = countdowns.first(where: { $0.id == id }) else { return }
        NotificationsManager.cancelNotifications(for: countdown)
        countdowns.removeAll { $0.id == id }
    }

    private func toggleCountdownPin(id: UUID) {
        guard let index = countdowns.firstIndex(where: { $0.id == id }) else { return }
        var countdown = countdowns.remove(at: index)
        countdown.isPinned.toggle()

        if countdown.isPinned {
            countdowns.insert(countdown, at: 0)
        } else {
            let insertIndex = countdowns.firstIndex(where: { !$0.isPinned }) ?? countdowns.count
            countdowns.insert(countdown, at: insertIndex)
        }
    }

    private func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: "routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
            NotificationsManager.syncNotifications(
                for: decoded,
                useAdaptive: settingsManager.settings.adaptiveReminderEngineEnabled
            )
        } else {
            routines = []
        }
    }

    private func saveRoutines() {
        if let data = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(data, forKey: "routines")
        }
    }

    private func loadCountdowns() {
        if let data = UserDefaults.standard.data(forKey: "countdowns"),
           let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data) {
            countdowns = decoded
            NotificationsManager.syncCountdownNotifications(
                for: decoded,
                includeMilestones: settingsManager.settings.countdownMilestoneNotificationsEnabled
            )
        } else {
            countdowns = []
        }
    }

    private func saveCountdowns() {
        if let data = try? JSONEncoder().encode(countdowns) {
            UserDefaults.standard.set(data, forKey: "countdowns")
        }
        NotificationsManager.syncCountdownNotifications(
            for: countdowns,
            includeMilestones: settingsManager.settings.countdownMilestoneNotificationsEnabled
        )
    }

    private var quickAddPanel: some View {
        let accent = settingsManager.settings.currentPalette.accentColor
        let addingCountdown = settingsManager.settings.countdownBetaEnabled && selectedTab == .countdowns

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(addingCountdown ? "Quick Countdown" : "Quick Routine")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        showQuickAdd = false
                    }
                    quickAddFocused = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(.liquidIconCircle(accent: accent, size: 30))
            }

            HStack(spacing: 10) {
                TextField(
                    addingCountdown
                    ? Translations.string("countdown_name", language: settingsManager.settings.language)
                    : Translations.string("routine_name", language: settingsManager.settings.language),
                    text: $quickAddName
                )
                .customStyle(isDarkMode: settingsManager.settings.isDarkMode)
                .focused($quickAddFocused)

                if addingCountdown {
                    DatePicker("", selection: $quickAddCountdownDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 12)
                }
            }

            HStack(spacing: 10) {
                Button(action: addQuickItem) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glassProminent)
                .disabled(quickAddName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(action: { openFullComposer() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Full")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private func handleCreateTap() {
        guard settingsManager.settings.quickCreateBetaEnabled else {
            openFullComposer()
            return
        }

        withAnimation(.easeOut(duration: 0.18)) {
            showQuickAdd.toggle()
        }
        quickAddFocused = showQuickAdd
    }

    private func openFullComposer(for tab: AppTab? = nil) {
        showQuickAdd = false
        quickAddFocused = false

        let contextTab = tab ?? selectedTab

        if settingsManager.settings.countdownBetaEnabled && contextTab == .countdowns {
            sheetMode = .createCountdown
        } else {
            sheetMode = .create
        }
    }

    private func addQuickItem() {
        let trimmed = quickAddName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if settingsManager.settings.countdownBetaEnabled && selectedTab == .countdowns {
            let dayStart = Calendar.current.startOfDay(for: quickAddCountdownDate)
            let targetDate = Calendar.current.date(byAdding: .hour, value: 9, to: dayStart) ?? dayStart
            let countdown = CountdownItem(
                name: trimmed,
                targetDate: targetDate,
                includesTime: false,
                reminders: [.dayOf]
            )
            countdowns.insert(countdown, at: 0)
            NotificationsManager.scheduleNotifications(
                for: countdown,
                includeMilestones: settingsManager.settings.countdownMilestoneNotificationsEnabled
            )
        } else {
            let defaultTaskName = Translations.string("task_name", language: settingsManager.settings.language)
            let routine = Routine(
                name: trimmed,
                tasks: [TaskItem(name: defaultTaskName, targetTime: 300)]
            )
            routines.insert(routine, at: 0)
        }

        quickAddName = ""
        quickAddCountdownDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        withAnimation(.easeOut(duration: 0.18)) {
            showQuickAdd = false
        }
        quickAddFocused = false
    }

    private func formattedTargetDate(for countdown: CountdownItem) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = countdown.includesTime ? .short : .none
        return formatter.string(from: countdown.targetDate)
    }

    private func formattedRemaining(for countdown: CountdownItem) -> String {
        if countdown.hasEnded {
            return Translations.string("ended", language: settingsManager.settings.language)
        }

        let total = Int(countdown.remainingInterval)
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return String(format: "%02dh %02dm", hours, minutes)
    }
}

private struct RoutineReorderDropDelegate: DropDelegate {
    let item: Routine
    @Binding var routines: [Routine]
    @Binding var draggedRoutine: Routine?

    func dropEntered(info: DropInfo) {
        guard let draggedRoutine else { return }
        guard draggedRoutine.id != item.id else { return }
        guard draggedRoutine.isPinned == item.isPinned else { return }

        guard let from = routines.firstIndex(where: { $0.id == draggedRoutine.id }),
              let to = routines.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        withAnimation {
            routines.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedRoutine = nil
        return true
    }
}

private struct CountdownReorderDropDelegate: DropDelegate {
    let item: CountdownItem
    @Binding var countdowns: [CountdownItem]
    @Binding var draggedCountdown: CountdownItem?

    func dropEntered(info: DropInfo) {
        guard let draggedCountdown else { return }
        guard draggedCountdown.id != item.id else { return }
        guard draggedCountdown.isPinned == item.isPinned else { return }

        guard let from = countdowns.firstIndex(where: { $0.id == draggedCountdown.id }),
              let to = countdowns.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        withAnimation {
            countdowns.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedCountdown = nil
        return true
    }
}
