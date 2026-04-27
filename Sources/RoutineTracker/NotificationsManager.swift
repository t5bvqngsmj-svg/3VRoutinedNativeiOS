import Foundation
import UserNotifications

struct NotificationHealthSnapshot {
    let authorizationStatus: UNAuthorizationStatus
    let pendingCount: Int
    let nextTriggerDate: Date?
    let nextIdentifier: String?
}

struct NotificationsManager {
    private static let delegateProxy = NotificationDelegateProxy()
    private static let adaptiveKey = "adaptiveReminderProfiles"

    private struct AdaptiveReminderProfile: Codable {
        var averageMinuteOfDay: Double
        var samples: Int
    }

    static func configureForegroundPresentation() {
        UNUserNotificationCenter.current().delegate = delegateProxy
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else {
                print("Local notifications authorized: \(granted)")
            }
        }
    }

    static func scheduleNotifications(for routine: Routine, useAdaptive: Bool = false) {
        guard routine.isScheduled else {
            cancelNotifications(for: routine)
            return
        }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Notification authorization error: \(error.localizedDescription)")
                        return
                    }
                    if granted {
                        scheduleAllNotifications(center: center, routine: routine, useAdaptive: useAdaptive)
                    } else {
                        print("Notification permission denied")
                    }
                }
            case .denied:
                print("Notification permission denied in settings")
            case .authorized, .provisional, .ephemeral:
                scheduleAllNotifications(center: center, routine: routine, useAdaptive: useAdaptive)
            @unknown default:
                print("Unknown notification authorization status")
            }
        }
    }

    static func syncNotifications(for routines: [Routine], useAdaptive: Bool = false) {
        for routine in routines {
            if routine.isScheduled {
                scheduleNotifications(for: routine, useAdaptive: useAdaptive)
            } else {
                cancelNotifications(for: routine)
            }
        }
    }

    private static func scheduleAllNotifications(center: UNUserNotificationCenter, routine: Routine, useAdaptive: Bool) {
        let requestIdentifiers = ["\(routine.id.uuidString)_routine"]
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)

        if let routineStart = effectiveRoutineStart(for: routine, useAdaptive: useAdaptive) {
            let content = UNMutableNotificationContent()
            content.title = "Routined"
            content.body = routine.name
            content.sound = .default

            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute], from: routineStart)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "\(routine.id.uuidString)_routine", content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule routine notification: \(error.localizedDescription)")
                }
            }
        }
    }

    static func recordAdaptiveCompletion(for routine: Routine, completionDate: Date = Date()) {
        guard routine.isScheduled else { return }

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: completionDate)
        guard let hour = comps.hour, let minute = comps.minute else { return }

        let minuteOfDay = Double(hour * 60 + minute)
        var profiles = loadAdaptiveProfiles()
        let key = routine.id.uuidString

        if var existing = profiles[key] {
            let total = (existing.averageMinuteOfDay * Double(existing.samples)) + minuteOfDay
            existing.samples += 1
            existing.averageMinuteOfDay = total / Double(existing.samples)
            profiles[key] = existing
        } else {
            profiles[key] = AdaptiveReminderProfile(averageMinuteOfDay: minuteOfDay, samples: 1)
        }

        saveAdaptiveProfiles(profiles)
    }

    private static func effectiveRoutineStart(for routine: Routine, useAdaptive: Bool) -> Date? {
        guard let scheduled = routine.scheduledTime else { return nil }
        guard useAdaptive else { return scheduled }

        let profiles = loadAdaptiveProfiles()
        guard let profile = profiles[routine.id.uuidString], profile.samples > 0 else { return scheduled }

        let roundedMinuteOfDay = Int(profile.averageMinuteOfDay.rounded())
        let hour = max(0, min(23, roundedMinuteOfDay / 60))
        let minute = max(0, min(59, roundedMinuteOfDay % 60))

        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? scheduled
    }

    private static func loadAdaptiveProfiles() -> [String: AdaptiveReminderProfile] {
        guard let data = UserDefaults.standard.data(forKey: adaptiveKey),
              let decoded = try? JSONDecoder().decode([String: AdaptiveReminderProfile].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveAdaptiveProfiles(_ profiles: [String: AdaptiveReminderProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: adaptiveKey)
        }
    }

    static func cancelNotifications(for routine: Routine) {
        let center = UNUserNotificationCenter.current()
        let requestIdentifiers = ["\(routine.id.uuidString)_routine"]
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)
    }

    static func scheduleNotifications(for countdown: CountdownItem, includeMilestones: Bool = false) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Notification authorization error: \(error.localizedDescription)")
                        return
                    }
                    if granted {
                        scheduleAllCountdownNotifications(center: center, countdown: countdown, includeMilestones: includeMilestones)
                    }
                }
            case .denied:
                print("Notification permission denied in settings")
            case .authorized, .provisional, .ephemeral:
                scheduleAllCountdownNotifications(center: center, countdown: countdown, includeMilestones: includeMilestones)
            @unknown default:
                print("Unknown notification authorization status")
            }
        }
    }

    static func syncCountdownNotifications(for countdowns: [CountdownItem], includeMilestones: Bool = false) {
        for countdown in countdowns {
            scheduleNotifications(for: countdown, includeMilestones: includeMilestones)
        }
    }

    private static func scheduleAllCountdownNotifications(center: UNUserNotificationCenter, countdown: CountdownItem, includeMilestones: Bool) {
        cancelNotifications(for: countdown)

        for reminder in countdown.reminders {
            guard let scheduledDate = notificationDate(for: countdown, reminder: reminder) else { continue }
            guard scheduledDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Countdown"
            content.body = countdown.name
            content.sound = .default

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: countdownNotificationId(countdownId: countdown.id, reminder: reminder),
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule countdown notification: \(error.localizedDescription)")
                }
            }
        }

        if includeMilestones {
            let milestones = milestoneNotificationDates(for: countdown)
            for (index, entry) in milestones.enumerated() {
                guard entry.date > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Countdown Milestone"
                content.body = "\(countdown.name): \(entry.label)"
                content.sound = .default

                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: entry.date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: countdownMilestoneNotificationId(countdownId: countdown.id, index: index),
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule milestone notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    static func cancelNotifications(for countdown: CountdownItem) {
        let center = UNUserNotificationCenter.current()
        let reminderIds = CountdownReminder.allCases.map { reminder in
            countdownNotificationId(countdownId: countdown.id, reminder: reminder)
        }
        let milestoneIds = Array(0..<3).map { index in
            countdownMilestoneNotificationId(countdownId: countdown.id, index: index)
        }
        let ids = reminderIds + milestoneIds
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func countdownNotificationId(countdownId: UUID, reminder: CountdownReminder) -> String {
        "\(countdownId.uuidString)_countdown_\(reminder.rawValue)"
    }

    private static func notificationDate(for countdown: CountdownItem, reminder: CountdownReminder) -> Date? {
        let calendar = Calendar.current

        let baseDate: Date
        if countdown.includesTime {
            baseDate = countdown.targetDate
        } else {
            let start = calendar.startOfDay(for: countdown.targetDate)
            baseDate = calendar.date(byAdding: .hour, value: 9, to: start) ?? start
        }

        switch reminder {
        case .dayOf:
            return baseDate
        case .dayBefore:
            return calendar.date(byAdding: .day, value: -1, to: baseDate)
        case .weekBefore:
            return calendar.date(byAdding: .day, value: -7, to: baseDate)
        }
    }

    private static func milestoneNotificationDates(for countdown: CountdownItem) -> [(label: String, date: Date)] {
        let totalInterval = countdown.targetDate.timeIntervalSince(countdown.createdAt)
        guard totalInterval > 0 else { return [] }

        let checkpoints: [(label: String, factor: Double)] = [
            ("75% complete", 0.25),
            ("50% complete", 0.50),
            ("25% remaining", 0.75)
        ]

        return checkpoints.compactMap { checkpoint in
            let date = countdown.createdAt.addingTimeInterval(totalInterval * checkpoint.factor)
            guard date < countdown.targetDate else { return nil }
            return (checkpoint.label, date)
        }
    }

    private static func countdownMilestoneNotificationId(countdownId: UUID, index: Int) -> String {
        "\(countdownId.uuidString)_countdown_milestone_\(index)"
    }

    static func fetchNotificationHealth(completion: @escaping (NotificationHealthSnapshot) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            center.getPendingNotificationRequests { requests in
                let next = requests
                    .compactMap { request -> (String, Date)? in
                        guard let nextDate = nextDate(from: request.trigger) else { return nil }
                        return (request.identifier, nextDate)
                    }
                    .sorted { $0.1 < $1.1 }
                    .first

                completion(
                    NotificationHealthSnapshot(
                        authorizationStatus: settings.authorizationStatus,
                        pendingCount: requests.count,
                        nextTriggerDate: next?.1,
                        nextIdentifier: next?.0
                    )
                )
            }
        }
    }

    private static func nextDate(from trigger: UNNotificationTrigger?) -> Date? {
        guard let trigger else { return nil }

        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return Calendar.current.date(from: calendarTrigger.dateComponents)
        }

        if let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return Date().addingTimeInterval(intervalTrigger.timeInterval)
        }

        if trigger is UNPushNotificationTrigger {
            return nil
        }

        return nil
    }
}

final class NotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
