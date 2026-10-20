import AppIntents
import Foundation

enum StackOffer {
    static func donate(done: @escaping (String) -> Void) {
        GroupTrace.writeApp("开始通过 IntentDonationManager 捐赠 Widget Intent")
        Task {
            let note: String
            do {
                try await IntentDonationManager.shared.donate(intent: StackBoardIntent())
                note = "已通过 IntentDonationManager 捐赠 Widget Intent"
            } catch {
                note = "捐赠 Widget Intent 失败：\(error.localizedDescription)"
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
                let match = IntentDonationMatchingPredicate.intentType(StackBoardIntent.self)
                try await IntentDonationManager.shared.deleteDonations(matching: match)
                note = "已清空 Widget Intent Donation"
            } catch {
                note = "清空 Widget Suggestion 失败：\(error.localizedDescription)"
            }
            GroupTrace.writeApp(note)
            await MainActor.run {
                done(note)
            }
        }
    }
}
