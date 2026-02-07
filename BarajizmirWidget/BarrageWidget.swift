import WidgetKit
import SwiftUI

struct BarrageWidget: Widget {
    let kind: String = "BarrageWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BarrageSelectionIntent.self,
            provider: BarrageWidgetTimeline()
        ) { entry in
            BarrageWidgetView(entry: entry)
        }
        .configurationDisplayName("Baraj Durumu")
        .description("Seçtiğiniz barajın doluluk oranını gösterir")
        .supportedFamilies([.systemSmall])
    }
}
