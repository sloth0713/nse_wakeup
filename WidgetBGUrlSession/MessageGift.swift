import Foundation
import Intents

enum MessageGift {
    static func send(
        name: String,
        chat: String,
        text: String,
        done: @escaping (String) -> Void
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanChat = chat.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanChat.isEmpty, !cleanText.isEmpty else {
            done("请填写联系人、会话标识和消息")
            return
        }

        let handle = INPersonHandle(value: cleanChat, type: .unknown)
        let person = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: cleanName,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: cleanChat
        )
        let intent = INSendMessageIntent(
            recipients: [person],
            outgoingMessageType: .outgoingMessageText,
            content: cleanText,
            speakableGroupName: INSpeakableString(spokenPhrase: cleanName),
            conversationIdentifier: cleanChat,
            serviceName: "WidgetBGUrlSession",
            sender: nil,
            attachments: nil
        )
        intent.suggestedInvocationPhrase = "给\(cleanName)发消息"

        let action = INInteraction(intent: intent, response: nil)
        action.direction = .outgoing
        action.identifier = cleanChat
        action.donate { error in
            let note: String
            if let error {
                note = "INSendMessageIntent 捐赠失败：\(error.localizedDescription)"
            } else {
                note = "已模拟发送给 \(cleanName)，并捐赠会话 \(cleanChat)"
            }
            GroupTrace.writeApp(note)
            DispatchQueue.main.async {
                done(note)
            }
        }
    }

    static func clear(done: @escaping (String) -> Void) {
        INInteraction.deleteAll { error in
            let note: String
            if let error {
                note = "清空消息捐赠失败：\(error.localizedDescription)"
            } else {
                note = "已清空本 App 的 SiriKit 捐赠"
            }
            GroupTrace.writeApp(note)
            DispatchQueue.main.async {
                done(note)
            }
        }
    }
}
