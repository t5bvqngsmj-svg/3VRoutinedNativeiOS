import SwiftUI
#if os(iOS)
import UIKit
import PhotosUI
#else
import AppKit
#endif
import Foundation

struct CreateRoutineView: View {
    @Binding var routines: [Routine]
    var editingRoutine: Routine? = nil
    var onUpdate: ((Routine) -> Void)? = nil

    @State private var routineName = ""
    @State private var tasks: [TaskItem] = []
    @State private var newTaskName = ""
    @State private var newTaskTargetMinutes = "5"
    @State private var isScheduledRoutine = false
    @State private var routineScheduledTime = Date()
    @State private var routineImage: PlatformImage?
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager

    init(routines: Binding<[Routine]>, editingRoutine: Routine? = nil, onUpdate: ((Routine) -> Void)? = nil) {
        self._routines = routines
        self.editingRoutine = editingRoutine
        self.onUpdate = onUpdate
        if let r = editingRoutine {
            _routineName = State(initialValue: r.name)
            _tasks = State(initialValue: r.tasks)
            _isScheduledRoutine = State(initialValue: r.isScheduled)
            _routineScheduledTime = State(initialValue: r.scheduledTime ?? Date())
            if let data = r.imageData {
                #if os(iOS)
                if let img = UIImage(data: data) {
                    _routineImage = State(initialValue: img)
                }
                #else
                if let img = NSImage(data: data) {
                    _routineImage = State(initialValue: img)
                }
                #endif
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(editingRoutine == nil
                         ? Translations.string("create_new", language: settingsManager.settings.language)
                         : "EDIT ROUTINE")
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .tracking(0.15)
                        .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                    
                    Text(editingRoutine == nil
                         ? Translations.string("new_routine", language: settingsManager.settings.language)
                         : routineName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                if let image = routineImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(18)
                        .padding(.horizontal, 24)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(18)
                        .padding(.horizontal, 24)
                    #endif
                }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField(Translations.string("routine_name", language: settingsManager.settings.language), text: $routineName)
                            .customStyle(isDarkMode: settingsManager.settings.isDarkMode)

                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: routineImage == nil ? "photo.badge.plus" : "photo.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                        .accessibilityLabel(Translations.string("upload_image", language: settingsManager.settings.language))
                    }
                    .padding(.horizontal, 24)

                    Toggle(isOn: $isScheduledRoutine) {
                        Text(Translations.string("scheduled_routine", language: settingsManager.settings.language))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: settingsManager.settings.currentPalette.accentColor))
                    .padding(12)
                    .glassCard(cornerRadius: 12)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    if isScheduledRoutine {
                        DatePicker(Translations.string("routine_time", language: settingsManager.settings.language), selection: $routineScheduledTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                            .padding(.horizontal, 24)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Translations.string("target", language: settingsManager.settings.language))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                            Text(totalTargetLabel)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        TextField(Translations.string("task_name", language: settingsManager.settings.language), text: $newTaskName)
                            .customStyle(isDarkMode: settingsManager.settings.isDarkMode)

                        TextField(Translations.string("minutes_short", language: settingsManager.settings.language), text: $newTaskTargetMinutes)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .customStyle(isDarkMode: settingsManager.settings.isDarkMode)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)

                        Button(action: addTask) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(settingsManager.settings.currentPalette.accentColor)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glass)
                        .clipShape(Circle())
                    }
                    .padding(.horizontal, 24)
                }
            }

            List {
                ForEach(tasks) { task in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode).opacity(0.6))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDarkMode: settingsManager.settings.isDarkMode))
                            Text(Translations.string("task_target", language: settingsManager.settings.language) + ": " + task.formattedTargetTime)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode))
                        }
                        Spacer()
                        Button(action: {
                            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                tasks.remove(at: index)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary(isDarkMode: settingsManager.settings.isDarkMode).opacity(0.7))
                        }
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 16)
                    .listRowBackground(Color.clear)
                }
                .onMove(perform: moveTask)
                .onDelete(perform: deleteTask)
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, .constant(.active))
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            VStack(spacing: 12) {
                Button(action: saveRoutine) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(Translations.string("save", language: settingsManager.settings.language))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .disabled(routineName.isEmpty || tasks.isEmpty)

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(Translations.string("cancel", language: settingsManager.settings.language))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .appBackground(settings: settingsManager.settings)
        .ignoresSafeArea()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $routineImage)
        }
    }

    private func addTask() {
        guard !newTaskName.isEmpty else { return }

        let minutes = Int(newTaskTargetMinutes) ?? 5
        let targetTime = TimeInterval(max(1, minutes) * 60)
        let newTask = TaskItem(name: newTaskName, targetTime: targetTime)

        tasks.append(newTask)
        newTaskName = ""
        newTaskTargetMinutes = "5"
    }
    
    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    private func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }

    private func saveRoutine() {
        guard !routineName.isEmpty && !tasks.isEmpty else { return }

        let imageData: Data?
        if let image = routineImage {
            #if os(iOS)
            imageData = image.jpegData(compressionQuality: 0.75)
            #else
            imageData = image.tiffRepresentation
            #endif
        } else {
            imageData = nil
        }

        let savedRoutine = Routine(
            id: editingRoutine?.id ?? UUID(),
            name: routineName,
            tasks: tasks,
            targetTime: totalTargetTime,
            imageData: imageData,
            isScheduled: isScheduledRoutine,
            scheduledTime: isScheduledRoutine ? routineScheduledTime : nil
        )

        if let onUpdate {
            onUpdate(savedRoutine)
        } else {
            routines.append(savedRoutine)
        }

        if savedRoutine.isScheduled {
            NotificationsManager.scheduleNotifications(for: savedRoutine)
        } else {
            NotificationsManager.cancelNotifications(for: savedRoutine)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private var totalTargetTime: TimeInterval {
        tasks.reduce(0) { $0 + $1.targetTime }
    }

    private var totalTargetLabel: String {
        guard !tasks.isEmpty else { return Translations.string("add_tasks_to_calculate_target", language: settingsManager.settings.language) }
        if isScheduledRoutine {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let lang = settingsManager.settings.language
            return "\(Translations.string("scheduled", language: lang)) \(Translations.string("at", language: lang)) \(formatter.string(from: routineScheduledTime))"
        }
        let minutes = Int(totalTargetTime) / 60
        let seconds = Int(totalTargetTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CustomTextFieldModifier: ViewModifier {
    let isDarkMode: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 12)
    }
}

extension View {
    func customStyle(isDarkMode: Bool) -> some View {
        modifier(CustomTextFieldModifier(isDarkMode: isDarkMode))
    }
}
