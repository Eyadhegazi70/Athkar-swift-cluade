import UserNotifications

/// ٦٠ تنبيهًا متتاليًا بفاصل يختاره المستخدم (حدّ iOS الأقصى ٦٤ تنبيهًا معلّقًا)،
/// وتُجدَّد في كل مرة يُفتح فيها التطبيق.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func schedule(on: Bool, everyMinutes: Int, texts: [String]) {
        center.removeAllPendingNotificationRequests()
        guard on else { return }
        let bodies = texts.isEmpty ? AthkarData.shared.notificationTexts() : texts
        guard !bodies.isEmpty else { return }

        center.requestAuthorization(options: [.alert, .sound]) { [center] granted, _ in
            guard granted else { return }
            for i in 1...60 {
                let content = UNMutableNotificationContent()
                content.title = "الأذكار"
                content.body = bodies[i % bodies.count]
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: Double(max(1, everyMinutes) * 60 * i), repeats: false)
                center.add(UNNotificationRequest(identifier: "athkar.\(i)", content: content, trigger: trigger))
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
