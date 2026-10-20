import Intents
import Social
import UniformTypeIdentifiers

final class ShareView: SLComposeServiceViewController {
    private var chatName = "没有系统推荐会话"

    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder = "输入要分享的内容"

        if let intent = extensionContext?.intent as? INSendMessageIntent {
            chatName = intent.recipients?.first?.displayName ?? "未命名会话"
            GroupTrace.writeShare("系统推荐会话：\(chatName)")
        } else {
            GroupTrace.writeShare("本次分享没有 INSendMessageIntent")
        }
    }

    override func isContentValid() -> Bool {
        !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    override func didSelectPost() {
        GroupTrace.writeShare("已分享给：\(chatName)")
        extensionContext?.completeRequest(returningItems: nil)
    }

    override func configurationItems() -> [Any]! {
        let chat = SLComposeSheetConfigurationItem()
        chat?.title = "系统推荐会话"
        chat?.value = chatName
        return [chat].compactMap { $0 }
    }
}
