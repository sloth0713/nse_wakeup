import AppIntents

struct StackBoardIntent: WidgetConfigurationIntent, PredictableIntent {
    static var title: LocalizedStringResource = "显示下载状态"
    static var description = IntentDescription("在智能叠放中显示下载状态小组件")

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(title: "查看下载状态")
        }
    }
}
