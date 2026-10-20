import Foundation
import WidgetKit

final class GroupSession: NSObject, URLSessionDownloadDelegate {
    static let shared = GroupSession()

    private let lock = NSLock()
    private var sessionMap: [String: URLSession] = [:]
    private var finishMap: [String: () -> Void] = [:]
    private var holdSession: URLSession?
    private lazy var workQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    func startLoad() {
        guard let remote = URL(string: GroupKeys.remoteLink) else {
            GroupTrace.writeWidget("远程地址无效")
            return
        }

        let sessionKey = "\(GroupKeys.sessionBase).\(UUID().uuidString)"
        let config = makeConfig(sessionKey: sessionKey)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: workQueue)
        holdSession = session

        var request = URLRequest(
            url: remote,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 60
        )
        request.setValue(sessionKey, forHTTPHeaderField: "X-Wake-Key")

        let task = session.downloadTask(with: request)
        task.taskDescription = sessionKey
        task.resume()

        lock.lock()
        sessionMap[sessionKey] = session
        lock.unlock()

        let box = GroupTrace.suite()
        box?.set(Date().timeIntervalSince1970, forKey: GroupKeys.lastStart)
        box?.set("小组件已提交后台下载", forKey: GroupKeys.lastStatus)
        GroupTrace.writeWidget("已提交后台下载 Session：\(sessionKey)")
    }

    func bindSession(sessionKey: String, finishBlock: @escaping () -> Void) {
        writeLine("收到后台 Session 事件：\(sessionKey)")
        guard sessionKey.hasPrefix("\(GroupKeys.sessionBase).") else {
            writeLine("忽略未知 Session")
            finishBlock()
            return
        }

        lock.lock()
        finishMap[sessionKey] = finishBlock
        if sessionMap[sessionKey] != nil {
            lock.unlock()
            writeLine("复用已有后台 Session")
            return
        }
        if let holdSession, holdSession.configuration.identifier == sessionKey {
            sessionMap[sessionKey] = holdSession
            lock.unlock()
            writeLine("复用发起时的 Session")
            return
        }
        lock.unlock()

        let config = makeConfig(sessionKey: sessionKey)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: workQueue)
        lock.lock()
        sessionMap[sessionKey] = session
        lock.unlock()
        writeLine("已重建后台 Session")
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        writeLine("下载成功，任务编号：\(downloadTask.taskIdentifier)")
        guard let folder = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: GroupKeys.groupName
        ) else {
            writeLine("无法读取 App Group 路径")
            return
        }

        let target = folder.appendingPathComponent(GroupKeys.savedName)
        try? FileManager.default.removeItem(at: target)
        do {
            try FileManager.default.copyItem(at: location, to: target)
            let attrs = try FileManager.default.attributesOfItem(atPath: target.path)
            let size = attrs[.size] as? Int64 ?? 0
            writeLine("文件已写入 App Group，大小：\(size) 字节")
        } catch {
            writeLine("移动下载文件失败：\(error.localizedDescription)")
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            let issue = error as NSError
            writeLine(
                "任务失败，编号：\(task.taskIdentifier)，域：\(issue.domain)，"
                    + "代码：\(issue.code)，错误：\(issue.localizedDescription)"
            )
            return
        }
        writeLine("任务完成，编号：\(task.taskIdentifier)")
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let sessionKey = session.configuration.identifier else {
            writeLine("后台 Session 缺少标识")
            session.finishTasksAndInvalidate()
            return
        }

        writeLine("已处理全部后台 Session 事件")
        let box = GroupTrace.suite()
        if isHostApp {
            let count = box?.integer(forKey: GroupKeys.wakeCount) ?? 0
            box?.set(count + 1, forKey: GroupKeys.wakeCount)
            box?.set(Date().timeIntervalSince1970, forKey: GroupKeys.wakeTime)
            box?.set("主 App 已被后台唤醒", forKey: GroupKeys.lastStatus)
        } else {
            box?.set("小组件下载已完成", forKey: GroupKeys.lastStatus)
            WidgetCenter.shared.reloadTimelines(ofKind: GroupKeys.widgetKind)
        }

        lock.lock()
        let finishBlock = finishMap.removeValue(forKey: sessionKey)
        sessionMap.removeValue(forKey: sessionKey)
        lock.unlock()

        session.finishTasksAndInvalidate()
        DispatchQueue.main.async {
            self.writeLine("调用系统后台事件完成回调")
            finishBlock?()
        }
    }

    func urlSession(
        _ session: URLSession,
        didBecomeInvalidWithError error: Error?
    ) {
        guard let error else {
            writeLine("Session 已正常失效")
            return
        }
        let issue = error as NSError
        writeLine(
            "Session 异常失效，域：\(issue.domain)，代码：\(issue.code)，"
                + "错误：\(issue.localizedDescription)"
        )
    }

    private var isHostApp: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private func writeLine(_ text: String) {
        if isHostApp {
            GroupTrace.writeApp(text)
        } else {
            GroupTrace.writeWidget(text)
        }
    }

    private func makeConfig(sessionKey: String) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.background(withIdentifier: sessionKey)
        config.sharedContainerIdentifier = GroupKeys.groupName
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.allowsCellularAccess = true
        return config
    }
}
