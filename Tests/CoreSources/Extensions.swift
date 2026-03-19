import Foundation
import CoreGraphics

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        hypot(x - point.x, y - point.y)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension TimeInterval {
    var asSecondsString: String {
        String(format: "%.2fs", self)
    }
}

extension Date {
    var shortDateString: String {
        Self.shortDateFormatter.string(from: self)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
