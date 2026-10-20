import AppIntents

struct BrowseFeedIntent: AppIntent, PredictableIntent {
    static var title: LocalizedStringResource = "继续刷视频"
    static var description = IntentDescription("打开 App 并继续浏览视频")
    static var openAppWhenRun = true

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(title: "继续刷视频")
        }
    }

    func perform() async throws -> some IntentResult {
        GroupTrace.writeApp("通过视频行为 Donation 打开")
        await MainActor.run {
            NotificationCenter.default.post(name: .hintHit, object: nil)
        }
        return .result()
    }
}

enum FeedGift {
    static func donate(done: @escaping (String) -> Void) {
        GroupTrace.writeApp("模拟用户已连续观看多条视频")
        Task {
            let note: String
            do {
                try await IntentDonationManager.shared.donate(intent: BrowseFeedIntent())
                note = "已捐赠「继续刷视频」用户行为"
            } catch {
                note = "视频行为捐赠失败：\(error.localizedDescription)"
            }
            GroupTrace.writeApp(note)
            await MainActor.run {
                done(note)
            }
        }
    }

    static func clear(done: @escaping (String) -> Void) {
        Task {
            let note: String
            do {
                let match = IntentDonationMatchingPredicate.intentType(BrowseFeedIntent.self)
                try await IntentDonationManager.shared.deleteDonations(matching: match)
                note = "已清空「继续刷视频」Donation"
            } catch {
                note = "清空视频行为捐赠失败：\(error.localizedDescription)"
            }
            GroupTrace.writeApp(note)
            await MainActor.run {
                done(note)
            }
        }
    }
}
