import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
enum HapticsManager {
    static var isEnabled = true

    static func success() {
        guard isEnabled else {
            return
        }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func failure() {
        guard isEnabled else {
            return
        }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    static func light() {
        guard isEnabled else {
            return
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
