import AppIntents
import CoreSpotlight

struct DemoVideoEntity: IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "演示视频")
    static var defaultQuery = DemoVideoQuery()

    let id: String
    let title: String
    let creator: String
    let summary: String
    let terms: [String]

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "作者：\(creator)"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let fields = defaultAttributeSet
        fields.title = title
        fields.displayName = title
        fields.contentDescription = summary
        fields.textContent = "\(title) \(creator) \(summary)"
        fields.keywords = terms
        return fields
    }

    static let samples = [
        DemoVideoEntity(
            id: "video.cat.surf",
            title: "猫咪冲浪挑战",
            creator: "测试作者小猫",
            summary: "一只猫咪在海边学习冲浪的演示视频",
            terms: ["猫咪冲浪", "海边", "测试作者小猫"]
        ),
        DemoVideoEntity(
            id: "video.tokyo.night",
            title: "东京夜景延时摄影",
            creator: "测试作者光影",
            summary: "东京城市夜景与车流延时摄影",
            terms: ["东京夜景", "延时摄影", "测试作者光影"]
        ),
        DemoVideoEntity(
            id: "video.widget.load",
            title: "Swift 小组件后台下载",
            creator: "测试作者开发者",
            summary: "使用 WidgetKit 和后台会话更新小组件",
            terms: ["Swift 小组件", "后台下载", "WidgetKit"]
        )
    ]
}

struct DemoVideoQuery: EntityQuery {
    func entities(for identifiers: [DemoVideoEntity.ID]) async throws -> [DemoVideoEntity] {
        DemoVideoEntity.samples.filter { video in
            identifiers.contains(video.id)
        }
    }

    func suggestedEntities() async throws -> [DemoVideoEntity] {
        DemoVideoEntity.samples
    }
}

struct OpenDemoVideoIntent: OpenIntent {
    static var title: LocalizedStringResource = "打开演示视频"

    @Parameter(title: "视频")
    var target: DemoVideoEntity

    func perform() async throws -> some IntentResult {
        let box = GroupTrace.suite()
        box?.set(target.title, forKey: GroupKeys.searchVideo)
        GroupTrace.writeApp("通过 IndexedEntity 打开视频：\(target.title)")
        await MainActor.run {
            NotificationCenter.default.post(name: .entityHit, object: target.title)
        }
        return .result()
    }
}

enum VideoSearchOffer {
    private static let searchIndex = CSSearchableIndex(name: "VideoSearchDemo")

    static func enable(done: @escaping (String) -> Void) {
        Task {
            let note: String
            do {
                try await searchIndex.indexAppEntities(DemoVideoEntity.samples)
                note = "实验组已写入 \(DemoVideoEntity.samples.count) 条 IndexedEntity"
            } catch {
                note = "写入 IndexedEntity 失败：\(error.localizedDescription)"
            }
            GroupTrace.writeApp(note)
            await MainActor.run {
                done(note)
            }
        }
    }

    static func disable(done: @escaping (String) -> Void) {
        Task {
            let note: String
            do {
                try await searchIndex.deleteAppEntities(ofType: DemoVideoEntity.self)
                note = "对照组已删除全部演示视频索引"
            } catch {
                note = "删除 IndexedEntity 失败：\(error.localizedDescription)"
            }
            GroupTrace.writeApp(note)
            await MainActor.run {
                done(note)
            }
        }
    }
}
