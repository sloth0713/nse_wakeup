# WidgetBGUrlSession

一个用于验证 iOS Widget 后台下载、App Intents、Siri Suggestions、Core Spotlight、Smart Stack 和分享面板会话建议的 Swift Demo。

> 仓库名称虽然是 `nse_wakeup`，但当前工程不包含 Notification Service Extension（NSE）。Widget 创建的后台 URLSession 完成事件由 Widget 的 `onBackgroundURLSessionEvents` 承接，不会可靠地唤醒主 App。

## 环境要求

- Xcode 26 或更高版本
- iOS 18 或更高版本
- 真机测试
- 支持 App Group 和 Siri Capability 的开发者账号

## Target

- `WidgetBGUrlSession`：主 App
- `WidgetBGUrlSessionWidget`：Widget Extension
- `WidgetBGUrlSessionShare`：Share Extension

## 标识配置

- App Bundle ID：`WidgetBGUrlSession.WidgetBGUrlSession`
- Widget Bundle ID：`WidgetBGUrlSession.WidgetBGUrlSession.Widget`
- Share Bundle ID：`WidgetBGUrlSession.WidgetBGUrlSession.Share`
- App Group：`group.WidgetBGUrlSession.WidgetBGUrlSession`
- Widget Kind：`DownloadWidget`

运行前需要将 Bundle ID、Development Team 和 App Group 修改为自己的配置，并保证主 App、Widget、Share Extension 使用同一个 App Group。

## 功能

### Widget 后台下载

Widget 在生成时间线时创建带 App Group 的 background URLSession：

```text
https://speed.cloudflare.com/__down?bytes=524288
```

该地址用于下载 512 KB 测试内容。下载完成后：

1. 系统通过 WidgetKit 的 `onBackgroundURLSessionEvents` 重新连接 Session。
2. 文件保存到 App Group 的 `latest.bin`。
3. Widget 写入日志并刷新时间线。

主 App 中保留了 `handleEventsForBackgroundURLSession` 实验代码，但 Widget 创建的 Session 正常不会转交给主 App。

### App Shortcut 与 Relevant Shortcut

- 注册“打开状态页”App Shortcut。
- 支持提交带时间窗口的 `INRelevantShortcut`。
- 支持通过 Relevant Shortcut 打开主 App。
- `INRelevantShortcutStore.setRelevantShortcuts` 是整表替换接口。

系统只把这些内容作为建议候选，不保证展示在 Siri Suggestions、锁屏或 Spotlight。

### Smart Stack Widget Suggestion

Widget 使用 `AppIntentConfiguration`，主 App 和 Widget 共用 `StackBoardIntent`。

- `StackBoardIntent` 遵循 `PredictableIntent`。
- 主 App 使用 `IntentDonationManager` 捐赠用户行为。
- 系统学习使用习惯后，可能把尚未添加的 Widget 临时建议到已有 Smart Stack。

用户需要已有 Smart Stack，并打开“智能轮换”和“小组件建议”。系统不保证立即展示。

### Siri Suggestions 视频行为

`BrowseFeedIntent` 表示可重复执行的“继续刷视频”动作。

- 模拟用户连续观看多条视频后捐赠。
- 没有注册为 App Shortcut，用于单独验证 Donation。
- 支持按 Intent 类型删除捐赠记录。

### Core Spotlight / IndexedEntity A/B

工程包含三条 `DemoVideoEntity`：

- 猫咪冲浪挑战
- 东京夜景延时摄影
- Swift 小组件后台下载

实验组调用 `indexAppEntities` 写入索引；对照组调用 `deleteAppEntities` 删除索引。点击 Spotlight 搜索结果后，`OpenDemoVideoIntent` 打开主 App 并记录视频标题。

工程还保留了一套基于 `CSSearchableItem` 的旧实验，用于搜索 `WGWakeBoard`。

### 分享面板会话建议

主 App 模拟消息发送完成后捐赠 `INSendMessageIntent`，Share Extension 在 `IntentsSupported` 中声明支持该 Intent。

系统可能在分享面板顶部推荐联系人或会话。通过推荐会话进入 Share Extension 时，扩展读取 `extensionContext.intent` 并记录日志。

## 真机验证

### Widget 下载

1. 安装并打开 App。
2. 将“下载唤醒”Widget 添加到桌面。
3. 等待 Widget 时间线刷新。
4. 回到主 App 查看“小组件日志”。
5. 正常情况下可看到提交、重连、下载完成和写入 App Group 的日志。

### IndexedEntity

1. 在 App 中点击“进入实验组：写入视频索引”。
2. 回到桌面 Spotlight。
3. 搜索“猫咪冲浪”“东京夜景”或“Swift 小组件”。
4. 点击结果，确认 App 记录对应视频标题。
5. 点击“进入对照组：删除视频索引”清理索引。

### INSendMessageIntent

1. 点击“模拟发送并捐赠”。
2. 确认捐赠成功。
3. 从照片或 Safari 打开系统分享面板。
4. 观察顶部是否出现测试联系人。

建议排序完全由系统控制，捐赠成功不代表一定展示。

## 重要限制

- Widget 后台下载不能作为唤醒或保活主 App 的手段。
- 本地通知不会静默拉起被用户杀掉的主 App。
- App Shortcut、Donation、Relevant Shortcut 不会增加 Siri Suggestions 的展示格数。
- Widget、Siri、Spotlight 和分享面板的建议均由系统排序，没有强制展示 API。
- 模拟器无法真实反映 Widget 后台调度、Spotlight 和 Siri Suggestions 行为。
- 当前工程没有实现 Universal Link、AASA、Web SEO 或 `.system.searchInApp`。

## 工程结构

```text
Shared/
  GroupKeys.swift
  GroupSession.swift
  GroupTrace.swift
  StackBoardIntent.swift

WidgetBGUrlSession/
  AppGate.swift
  FeedGift.swift
  HintOffer.swift
  MessageGift.swift
  OpenBoard.swift
  StackOffer.swift
  StatusBoard.swift
  VideoSearchOffer.swift
  WakeNotice.swift
  WidgetBGUrlSessionApp.swift

WidgetBGUrlSessionWidget/
  DownloadWidget.swift

WidgetBGUrlSessionShare/
  ShareView.swift
```

## License

仅用于技术验证和学习。
