import Foundation
import UserNotifications

struct NotificationsManager {
    private static let delegateProxy = NotificationDelegateProxy()

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

    static func scheduleNotifications(for routine: Routine) {
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
                        scheduleAllNotifications(center: center, routine: routine)
                    } else {
                        print("Notification permission denied")
                    }
                }
            case .denied:
                print("Notification permission denied in settings")
            case .authorized, .provisional, .ephemeral:
                scheduleAllNotifications(center: center, routine: routine)
            @unknown default:
                print("Unknown notification authorization status")
            }
        }
    }

    static func syncNotifications(for routines: [Routine]) {
        for routine in routines {
            if routine.isScheduled {
                scheduleNotifications(for: routine)
            } else {
                cancelNotifications(for: routine)
            }
        }
    }

    private static func scheduleAllNotifications(center: UNUserNotificationCenter, routine: Routine) {
        let requestIdentifiers = ["\(routine.id.uuidString)_routine"]
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)

        if let routineStart = routine.scheduledTime {
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

    static func cancelNotifications(for routine: Routine) {
        let center = UNUserNotificationCenter.current()
        let requestIdentifiers = ["\(routine.id.uuidString)_routine"]
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)
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
