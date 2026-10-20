import AppIntents
import CoreSpotlight
import Foundation
import Intents
import UniformTypeIdentifiers

enum HintOffer {
    private static var holdActivity: NSUserActivity?
    private static var holdQuery: CSSearchQuery?

    static func pushHints(delay: TimeInterval, span: TimeInterval, done: @escaping () -> Void) {
        GroupTrace.writeApp("开始提交 Relevant Shortcut")
        let fields = makeAttrs()
        let activity = NSUserActivity(activityType: GroupKeys.hintType)
        activity.title = "相关快捷打开状态页"
        activity.suggestedInvocationPhrase = "打开状态页"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = GroupKeys.hintType
        activity.keywords = Set(fields.keywords ?? [])
        activity.contentAttributeSet = fields
        activity.requiredUserInfoKeys = ["origin"]
        activity.addUserInfoEntries(from: ["origin": "relevant"])
        activity.becomeCurrent()
        holdActivity = activity

        let shortcut = INShortcut(userActivity: activity)
        let hint = INRelevantShortcut(shortcut: shortcut)
        hint.shortcutRole = .action

        let begin = Date().addingTimeInterval(delay)
        let finish = begin.addingTimeInterval(span)
        hint.relevanceProviders = [INDateRelevanceProvider(start: begin, end: finish)]

        donateBoard()
        indexSearch {
            INRelevantShortcutStore.default.setRelevantShortcuts([hint]) { error in
                if let error {
                    let issue = error as NSError
                    GroupTrace.writeApp(
                        "提交 Relevant Shortcut 失败：域 \(issue.domain) 代码 \(issue.code) \(issue.localizedDescription)"
                    )
                } else {
                    let clock = DateFormatter()
                    clock.dateFormat = "HH:mm"
                    GroupTrace.writeApp(
                        "已提交 Relevant Shortcut，相关窗口 \(clock.string(from: begin))–\(clock.string(from: finish))"
                    )
                }
                DispatchQueue.main.async(execute: done)
            }
        }
    }

    static func clearHints(done: @escaping () -> Void) {
        GroupTrace.writeApp("开始清空 Relevant Shortcut")
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [GroupKeys.hintType]) { error in
            if let error {
                GroupTrace.writeApp("删除 Spotlight 索引失败：\(error.localizedDescription)")
            } else {
                GroupTrace.writeApp("已删除 Spotlight 索引")
            }
        }
        INRelevantShortcutStore.default.setRelevantShortcuts([]) { error in
            if let error {
                GroupTrace.writeApp("清空 Relevant Shortcut 失败：\(error.localizedDescription)")
            } else {
                GroupTrace.writeApp("已清空 Relevant Shortcut")
            }
            DispatchQueue.main.async(execute: done)
        }
    }

    static func checkIndex(done: @escaping (Int, String) -> Void) {
        var titles: [String] = []
        let context = CSSearchQueryContext()
        context.fetchAttributes = ["title", "displayName"]
        let queryText = "uniqueIdentifier == '\(GroupKeys.hintType)' || title == '*\(GroupKeys.searchMark)*'cd"
        let query = CSSearchQuery(queryString: queryText, queryContext: context)
        holdQuery = query
        query.foundItemsHandler = { rows in
            for entry in rows {
                titles.append(entry.attributeSet.title ?? entry.uniqueIdentifier)
            }
        }
        query.completionHandler = { error in
            if let error {
                GroupTrace.writeApp("本机索引查询失败：\(error.localizedDescription)")
                DispatchQueue.main.async {
                    done(0, "查询失败：\(error.localizedDescription)")
                }
                return
            }
            GroupTrace.writeApp("本机索引命中 \(titles.count) 条")
            DispatchQueue.main.async {
                if titles.isEmpty {
                    done(0, "本机索引是空的，系统 Spotlight 不会有结果")
                } else {
                    done(titles.count, "本机已有：\(titles.joined(separator: "、"))")
                }
            }
        }
        query.start()
        GroupTrace.writeApp("已开始查询本机 Spotlight 索引")
    }

    private static func makeAttrs() -> CSSearchableItemAttributeSet {
        let fields = CSSearchableItemAttributeSet(contentType: .text)
        let titleText = "\(GroupKeys.searchMark) 下载唤醒状态页"
        fields.title = titleText
        fields.displayName = titleText
        fields.contentDescription = "WidgetBGUrlSession 后台下载唤醒"
        fields.textContent = "\(titleText) WidgetBGUrlSession 下载 唤醒 小组件"
        fields.keywords = [GroupKeys.searchMark, "下载唤醒状态页", "WidgetBGUrlSession"]
        fields.alternateNames = [GroupKeys.searchMark, "下载唤醒状态页"]
        fields.identifier = GroupKeys.hintType
        return fields
    }

    private static func donateBoard() {
        Task {
            do {
                try await IntentDonationManager.shared.donate(intent: OpenBoardIntent())
                GroupTrace.writeApp("已捐赠 App Intent")
            } catch {
                GroupTrace.writeApp("捐赠 App Intent 失败：\(error.localizedDescription)")
            }
        }
    }

    private static func indexSearch(done: @escaping () -> Void) {
        if !CSSearchableIndex.isIndexingAvailable() {
            GroupTrace.writeApp("本机不支持 Spotlight 索引")
            done()
            return
        }
        let searchRow = CSSearchableItem(
            uniqueIdentifier: GroupKeys.hintType,
            domainIdentifier: "hint",
            attributeSet: makeAttrs()
        )
        searchRow.expirationDate = .distantFuture
        CSSearchableIndex.default().indexSearchableItems([searchRow]) { error in
            if let error {
                GroupTrace.writeApp("写入 Spotlight 失败：\(error.localizedDescription)")
                done()
                return
            }
            GroupTrace.writeApp("已写入 Spotlight 索引，请搜 \(GroupKeys.searchMark)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                checkIndex { _, _ in
                    done()
                }
            }
        }
    }
}
