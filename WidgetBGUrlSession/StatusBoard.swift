import CoreSpotlight
import SwiftUI
import UIKit
import WidgetKit

struct StatusBoard: View {
    @State private var wakeCount = 0
    @State private var wakeTime = "尚未被后台下载唤醒"
    @State private var startTime = "小组件尚未发起下载"
    @State private var statusText = "等待小组件刷新时间线"
    @State private var appTrace: [String] = []
    @State private var widgetTrace: [String] = []
    @State private var shareTrace: [String] = []
    @State private var showToast = false
    @State private var toastText = "主 App 在前台收到后台下载事件"
    @State private var hideTask: Task<Void, Never>?
    @State private var hintText = "尚未提交"
    @State private var stackText = "尚未提交"
    @State private var feedText = "尚未捐赠"
    @State private var searchIndexText = "尚未分组"
    @State private var searchVideoText = "尚未通过 Spotlight 打开视频"
    @State private var chatName = "测试好友"
    @State private var chatCode = "chat.test.friend"
    @State private var messageText = "分享这个视频给你"
    @State private var giftText = "尚未捐赠"

    var body: some View {
        NavigationStack {
            Form {
                Section("当前状态") {
                    LabeledContent("状态", value: statusText)
                    LabeledContent("发起时间", value: startTime)
                    LabeledContent("唤醒次数", value: "\(wakeCount)")
                    LabeledContent("最近唤醒", value: wakeTime)
                    Button("刷新状态", action: loadBoard)
                    Button("刷新小组件时间线", action: reloadWidget)
                }

                Section("Relevant Shortcut") {
                    Text("三个建议入口没有展示义务，空是常见结果。之前带了 widgetKind，系统会去智能叠放推小组件，不会推快捷卡片。现在只提交操作本身。先打开「快捷指令」App，搜本 App 或「打开状态页」，那里一定有。再只点一次「现在起 30 分钟」，看锁屏 Donation（开发者开关）或空搜索建议。")
                        .font(.footnote)
                    LabeledContent("提交结果", value: hintText)
                    Button("提交：现在起 30 分钟相关", action: pushNow)
                    Button("提交：2 分钟后开始相关", action: pushSoon)
                    Button("检查本机索引", action: checkIndex)
                    Button("打开系统设置", action: openSettings)
                    Button("清空相关快捷操作", role: .destructive, action: clearHints)
                }

                Section("Smart Stack Widget Suggestion") {
                    Text("Widget 与主 App 共用 StackBoardIntent。用户查看对应内容后，通过 IntentDonationManager 捐赠；系统学习习惯后，可能把尚未添加的 Widget 插入已有 Smart Stack。")
                        .font(.footnote)
                    LabeledContent("捐赠结果", value: stackText)
                    Button("捐赠 Widget Intent", action: donateStack)
                    Button("清空 Widget Intent Donation", role: .destructive, action: clearStack)
                }

                Section("Siri Suggestions 视频行为") {
                    Text("模拟用户连续观看多条视频后，捐赠一个可重复执行的「继续刷视频」动作。这个 Intent 没有注册为 App Shortcut，用于单独验证 Donation 建议。")
                        .font(.footnote)
                    LabeledContent("捐赠结果", value: feedText)
                    Button("模拟看完多个视频并捐赠", action: donateFeed)
                    Button("清空视频行为 Donation", role: .destructive, action: clearFeed)
                }

                Section("Core Spotlight / IndexedEntity A/B") {
                    Text("实验组写入三条演示视频实体；对照组删除这些实体。写入后回桌面搜「猫咪冲浪」「东京夜景」或「Swift 小组件」。")
                        .font(.footnote)
                    LabeledContent("实验状态", value: searchIndexText)
                    LabeledContent("最近打开", value: searchVideoText)
                    Button("进入实验组：写入视频索引", action: enableVideoSearch)
                    Button("进入对照组：删除视频索引", role: .destructive, action: disableVideoSearch)
                }

                Section("分享面板会话建议") {
                    Text("这个按钮模拟消息已经发送成功，然后捐赠 INSendMessageIntent。系统会学习该会话，并可能把它放到分享面板顶部。")
                        .font(.footnote)
                    TextField("联系人", text: $chatName)
                    TextField("会话标识", text: $chatCode)
                    TextField("消息", text: $messageText)
                    LabeledContent("捐赠结果", value: giftText)
                    Button("模拟发送并捐赠", action: donateMessage)
                    Button("清空消息捐赠", role: .destructive, action: clearMessage)
                }

                Section("验证步骤") {
                    Text(
                        """
                        1. 将「下载唤醒」小组件添加到桌面。
                        2. 立刻把主 App 退到后台，或从多任务中划掉。
                        3. 小组件会在时间线刷新时通过 App Group 提交后台下载。
                        4. 下载完成后，系统调用主 App 的 handleEventsForBackgroundURLSession 拉起主进程。
                        """
                    )
                    .font(.footnote)
                }

                Section("主 App 日志") {
                    if appTrace.isEmpty {
                        Text("暂无日志")
                    } else {
                        ForEach(appTrace.indices.reversed(), id: \.self) { index in
                            Text(appTrace[index])
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("小组件日志") {
                    if widgetTrace.isEmpty {
                        Text("暂无日志")
                    } else {
                        ForEach(widgetTrace.indices.reversed(), id: \.self) { index in
                            Text(widgetTrace[index])
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("分享扩展日志") {
                    if shareTrace.isEmpty {
                        Text("暂无日志")
                    } else {
                        ForEach(shareTrace.indices.reversed(), id: \.self) { index in
                            Text(shareTrace[index])
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section {
                    Button("清空日志", role: .destructive, action: clearTrace)
                }
            }
            .navigationTitle("后台下载唤醒")
        }
        .onAppear(perform: loadBoard)
        .onContinueUserActivity(GroupKeys.hintType) { _ in
            GroupTrace.writeApp("SwiftUI 收到 Relevant Shortcut")
            loadBoard()
            showHintToast()
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            let key = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            guard key == GroupKeys.hintType else { return }
            GroupTrace.writeApp("SwiftUI 收到 Spotlight 搜索")
            loadBoard()
            showHintToast()
        }
        .onReceive(NotificationCenter.default.publisher(for: .wakeHit)) { _ in
            showWakeToast()
            loadBoard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hintHit)) { _ in
            loadBoard()
            showHintToast()
        }
        .onReceive(NotificationCenter.default.publisher(for: .entityHit)) { notice in
            loadBoard()
            let title = notice.object as? String ?? searchVideoText
            toastText = "已从 Spotlight 打开：\(title)"
            showBanner()
        }
        .overlay(alignment: .top) {
            if showToast {
                Text(toastText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.82), in: Capsule())
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func loadBoard() {
        let box = GroupTrace.suite()
        wakeCount = box?.integer(forKey: GroupKeys.wakeCount) ?? 0
        statusText = box?.string(forKey: GroupKeys.lastStatus) ?? "等待小组件刷新时间线"
        appTrace = GroupTrace.readApp()
        widgetTrace = GroupTrace.readWidget()
        shareTrace = GroupTrace.readShare()
        searchVideoText = box?.string(forKey: GroupKeys.searchVideo) ?? "尚未通过 Spotlight 打开视频"
        wakeTime = formatStamp(box?.double(forKey: GroupKeys.wakeTime), empty: "尚未被后台下载唤醒")
        startTime = formatStamp(box?.double(forKey: GroupKeys.lastStart), empty: "小组件尚未发起下载")
    }

    private func pushNow() {
        submitHints(delay: 0, span: 30 * 60)
    }

    private func pushSoon() {
        submitHints(delay: 2 * 60, span: 30 * 60)
    }

    private func submitHints(delay: TimeInterval, span: TimeInterval) {
        hintText = "正在提交…"
        GroupTrace.writeApp("点击提交相关快捷操作")
        loadBoard()
        HintOffer.pushHints(delay: delay, span: span) {
            hintText = lastHintLine()
            loadBoard()
        }
    }

    private func clearHints() {
        hintText = "正在清空…"
        HintOffer.clearHints {
            hintText = lastHintLine()
            loadBoard()
        }
    }

    private func donateStack() {
        stackText = "正在捐赠…"
        StackOffer.donate { note in
            stackText = note
            loadBoard()
        }
    }

    private func clearStack() {
        stackText = "正在清空…"
        StackOffer.clear { note in
            stackText = note
            loadBoard()
        }
    }

    private func donateFeed() {
        feedText = "正在捐赠…"
        FeedGift.donate { note in
            feedText = note
            loadBoard()
        }
    }

    private func clearFeed() {
        feedText = "正在清空…"
        FeedGift.clear { note in
            feedText = note
            loadBoard()
        }
    }

    private func enableVideoSearch() {
        searchIndexText = "正在写入…"
        VideoSearchOffer.enable { note in
            searchIndexText = note
            loadBoard()
        }
    }

    private func disableVideoSearch() {
        searchIndexText = "正在删除…"
        VideoSearchOffer.disable { note in
            searchIndexText = note
            loadBoard()
        }
    }

    private func donateMessage() {
        giftText = "正在捐赠…"
        MessageGift.send(name: chatName, chat: chatCode, text: messageText) { note in
            giftText = note
            loadBoard()
        }
    }

    private func clearMessage() {
        giftText = "正在清空…"
        MessageGift.clear { note in
            giftText = note
            loadBoard()
        }
    }

    private func checkIndex() {
        hintText = "正在查本机索引…"
        HintOffer.checkIndex { _, line in
            hintText = line
            loadBoard()
        }
    }

    private func openSettings() {
        guard let link = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(link)
    }

    private func lastHintLine() -> String {
        GroupTrace.readApp().last { line in
            line.contains("Relevant Shortcut") || line.contains("本机索引") || line.contains("Spotlight")
        } ?? "回调未写入日志"
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
        GroupTrace.writeApp("已请求刷新全部小组件时间线")
        loadBoard()
    }

    private func clearTrace() {
        GroupTrace.clearAll()
        appTrace = []
        widgetTrace = []
        shareTrace = []
    }

    private func formatStamp(_ stamp: Double?, empty: String) -> String {
        guard let stamp, stamp > 0 else { return empty }
        return Date(timeIntervalSince1970: stamp).formatted(date: .numeric, time: .standard)
    }

    private func showWakeToast() {
        toastText = "主 App 在前台收到后台下载事件"
        showBanner()
    }

    private func showHintToast() {
        toastText = "已从 Relevant Shortcut 打开"
        showBanner()
    }

    private func showBanner() {
        hideTask?.cancel()
        withAnimation {
            showToast = true
        }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation {
                showToast = false
            }
        }
    }
}
