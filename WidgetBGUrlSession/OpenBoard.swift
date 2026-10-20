import AppIntents

struct OpenBoardIntent: AppIntent {
    static var title: LocalizedStringResource = "相关快捷打开状态页"
    static var description = IntentDescription("打开下载唤醒状态页")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        GroupTrace.writeApp("通过 App Intent 打开")
        await MainActor.run {
            NotificationCenter.default.post(name: .hintHit, object: nil)
        }
        return .result()
    }
}

struct BoardPhrases: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenBoardIntent(),
            phrases: [
                "打开\(.applicationName)状态页",
                "用\(.applicationName)打开状态页"
            ],
            shortTitle: "打开状态页",
            systemImageName: "arrow.down.circle"
        )
    }
}
