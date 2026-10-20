import CoreSpotlight
import UIKit
import UserNotifications

extension Notification.Name {
    static let wakeHit = Notification.Name("wakeHit")
    static let hintHit = Notification.Name("hintHit")
    static let entityHit = Notification.Name("entityHit")
}

final class AppGate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        GroupTrace.writeApp("主 App didFinishLaunching")
        WakeNotice.askAlert()
        return true
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        GroupTrace.writeApp("系统调用 handleEventsForBackgroundURLSession")
        if application.applicationState == .active {
            NotificationCenter.default.post(name: .wakeHit, object: nil)
        } else {
            WakeNotice.sendAlert(
                title: "主 App 已唤醒",
                body: "小组件后台下载完成，系统已拉起主进程"
            )
        }
        GroupSession.shared.bindSession(sessionKey: identifier, finishBlock: completionHandler)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType {
            let key = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            guard key == GroupKeys.hintType else { return false }
            GroupTrace.writeApp("通过 Spotlight 搜索打开 App")
            NotificationCenter.default.post(name: .hintHit, object: nil)
            return true
        }
        guard userActivity.activityType == GroupKeys.hintType else { return false }
        GroupTrace.writeApp("通过 Relevant Shortcut 打开 App")
        NotificationCenter.default.post(name: .hintHit, object: nil)
        return true
    }
}
