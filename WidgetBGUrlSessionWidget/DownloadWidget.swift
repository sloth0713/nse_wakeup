import AppIntents
import SwiftUI
import WidgetKit

struct TimeEntry: TimelineEntry {
    let date: Date
    let statusText: String
    let startText: String
    let wakeCount: Int
}

struct TimeProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TimeEntry {
        makeEntry(statusText: "准备发起后台下载")
    }

    func snapshot(for configuration: StackBoardIntent, in context: Context) async -> TimeEntry {
        makeEntry(statusText: readStatus())
    }

    func timeline(for configuration: StackBoardIntent, in context: Context) async -> Timeline<TimeEntry> {
        if !context.isPreview {
            GroupSession.shared.startLoad()
        }
        let entry = makeEntry(statusText: readStatus())
        let nextDate = Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(nextDate))
    }

    private func readStatus() -> String {
        GroupTrace.suite()?.string(forKey: GroupKeys.lastStatus) ?? "等待时间线刷新"
    }

    private func makeEntry(statusText: String) -> TimeEntry {
        let box = GroupTrace.suite()
        let stamp = box?.double(forKey: GroupKeys.lastStart) ?? 0
        let startText: String
        if stamp > 0 {
            startText = Date(timeIntervalSince1970: stamp).formatted(date: .omitted, time: .standard)
        } else {
            startText = "尚未发起"
        }
        return TimeEntry(
            date: Date(),
            statusText: statusText,
            startText: startText,
            wakeCount: box?.integer(forKey: GroupKeys.wakeCount) ?? 0
        )
    }
}

struct WidgetBoard: View {
    let entry: TimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("后台下载唤醒")
                .font(.headline)
            Text(entry.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("发起：\(entry.startText)")
                .font(.caption)
            Text("唤醒 \(entry.wakeCount) 次")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct DownloadWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: GroupKeys.widgetKind,
            intent: StackBoardIntent.self,
            provider: TimeProvider()
        ) { entry in
            WidgetBoard(entry: entry)
        }
        .configurationDisplayName("下载唤醒")
        .description("时间线刷新时通过 App Group 发起后台下载，完成后在小组件内处理")
        .supportedFamilies([.systemSmall, .systemMedium])
        .onBackgroundURLSessionEvents(
            matching: { sessionKey in
                sessionKey.hasPrefix(GroupKeys.sessionBase)
            },
            { sessionKey, finishBlock in
                GroupSession.shared.bindSession(sessionKey: sessionKey, finishBlock: finishBlock)
            }
        )
    }
}
