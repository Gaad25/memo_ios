// memo/Features/Shared/Haptics.swift

import SwiftUI
import UIKit

struct Haptics {
    static func light() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
