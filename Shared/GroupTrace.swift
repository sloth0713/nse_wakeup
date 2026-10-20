import Foundation
import OSLog

enum GroupTrace {
    private static let logger = Logger(
        subsystem: "WidgetBGUrlSession.WidgetBGUrlSession",
        category: "ShareSession"
    )

    static func writeApp(_ text: String) {
        append(text, key: GroupKeys.appTrace, tag: "APP")
    }

    static func writeWidget(_ text: String) {
        append(text, key: GroupKeys.widgetTrace, tag: "WID")
    }

    static func writeShare(_ text: String) {
        append(text, key: GroupKeys.shareTrace, tag: "SHARE")
    }

    static func readApp() -> [String] {
        suite()?.stringArray(forKey: GroupKeys.appTrace) ?? []
    }

    static func readWidget() -> [String] {
        suite()?.stringArray(forKey: GroupKeys.widgetTrace) ?? []
    }

    static func readShare() -> [String] {
        suite()?.stringArray(forKey: GroupKeys.shareTrace) ?? []
    }

    static func clearAll() {
        let box = suite()
        box?.removeObject(forKey: GroupKeys.appTrace)
        box?.removeObject(forKey: GroupKeys.widgetTrace)
        box?.removeObject(forKey: GroupKeys.shareTrace)
    }

    static func suite() -> UserDefaults? {
        UserDefaults(suiteName: GroupKeys.groupName)
    }

    private static func append(_ text: String, key: String, tag: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let process = ProcessInfo.processInfo.processIdentifier
        let line = "\(stamp) \(tag) pid=\(process) \(text)"
        logger.notice("\(line, privacy: .public)")

        guard let box = suite() else { return }
        var lines = box.stringArray(forKey: key) ?? []
        lines.append(line)
        if lines.count > 40 {
            lines.removeFirst(lines.count - 40)
        }
        box.set(lines, forKey: key)
        box.synchronize()
    }
}
