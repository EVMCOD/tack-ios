import WidgetKit
import SwiftUI

@main
struct TackWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        InboxWidget()
    }
}
