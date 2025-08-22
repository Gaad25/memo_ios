import WidgetKit
import SwiftUI

@main
struct MemoTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        MemoTimerWidget()
        MemoTimerWidgetControl()
        MemoTimerWidgetLiveActivity()
    }
}
