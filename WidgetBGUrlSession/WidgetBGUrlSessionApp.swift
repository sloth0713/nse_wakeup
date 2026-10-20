import SwiftUI

@main
struct WidgetBGUrlSessionApp: App {
    @UIApplicationDelegateAdaptor(AppGate.self) private var appGate

    var body: some Scene {
        WindowGroup {
            StatusBoard()
        }
    }
}
