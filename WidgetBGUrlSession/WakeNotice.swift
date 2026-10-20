import UserNotifications

enum WakeNotice {
    static func askAlert() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { allowed, error in
            guard allowed, error == nil else {
                GroupTrace.writeApp("通知授权失败：\(error?.localizedDescription ?? "用户未授权")")
                return
            }
            GroupTrace.writeApp("通知授权成功")
        }
    }

    static func sendAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
