import Foundation
import CoreGraphics

enum CalibrationEngine {
    static func summarize(tapSamples: [TapSample], dragSamples: [DragSample]) -> CalibrationResult {
        let tapDistances = tapSamples.map(\.distance)
        let tapMean = mean(tapDistances)
        let tapStdDev = standardDeviation(tapDistances, mean: tapMean)

        let dragDeviations = dragSamples.map(\.meanDeviation)
        let dragMean = mean(dragDeviations)

        let reactionTimes = tapSamples.map(\.elapsed)
        let averageReaction = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        let confidence = confidenceScore(
            tapSamples: tapSamples,
            dragSamples: dragSamples,
            reactionTimes: reactionTimes
        )

        return CalibrationResult(
            tapMeanError: tapMean,
            tapStdDev: tapStdDev,
            dragMeanDeviation: dragMean,
            averageReactionTime: averageReaction,
            tapSampleCount: tapSamples.count,
            dragSampleCount: dragSamples.count,
            confidenceScore: confidence
        )
    }

    static func generateAdaptiveProfile(from result: CalibrationResult) -> InteractionProfile {
        let tapSeverity = (result.tapStdDev / 28.0).clamped(to: 0...1)
        let dragSeverity = (result.dragMeanDeviation / 34.0).clamped(to: 0...1)
        let reactionSeverity = CGFloat((result.averageReactionTime / 2.4).clamped(to: 0...1))

        let compositeSeverity = ((tapSeverity * 0.5) + (dragSeverity * 0.3) + (reactionSeverity * 0.2)).clamped(to: 0...1)

        let buttonScale = (1.0 + (compositeSeverity * 0.55)).clamped(to: 1.0...1.65)
        let gridSpacing = (10.0 + (compositeSeverity * 18.0)).clamped(to: 10...28)
        let holdDuration = (0.05 + (Double(compositeSeverity) * 0.45)).clamped(to: 0.05...0.5)
        let swipeThreshold = (24.0 + (compositeSeverity * 42.0)).clamped(to: 24...66)

        return InteractionProfile(
            buttonScale: buttonScale,
            gridSpacing: gridSpacing,
            holdDuration: holdDuration,
            swipeThreshold: swipeThreshold
        )
    }

    private static func mean(_ values: [CGFloat]) -> CGFloat {
        guard !values.isEmpty else {
            return 0
        }
        return values.reduce(0, +) / CGFloat(values.count)
    }

    private static func standardDeviation(_ values: [CGFloat], mean: CGFloat) -> CGFloat {
        guard !values.isEmpty else {
            return 0
        }

        let variance = values.reduce(CGFloat.zero) { partial, value in
            let delta = value - mean
            return partial + (delta * delta)
        } / CGFloat(values.count)

        return sqrt(variance)
    }

    private static func confidenceScore(
        tapSamples: [TapSample],
        dragSamples: [DragSample],
        reactionTimes: [TimeInterval]
    ) -> Double {
        let tapCoverage = Double(min(1.0, Double(tapSamples.count) / 10.0))
        let dragCoverage = Double(min(1.0, Double(dragSamples.count) / 4.0))
        let coverageScore = (tapCoverage * 0.65) + (dragCoverage * 0.35)

        let validReactionCount = reactionTimes.filter { (0.12...4.0).contains($0) }.count
        let reactionScore: Double
        if reactionTimes.isEmpty {
            reactionScore = 0
        } else {
            reactionScore = Double(validReactionCount) / Double(reactionTimes.count)
        }

        let validDragTraceCount = dragSamples.filter { $0.points.count >= 8 }.count
        let dragTraceScore: Double
        if dragSamples.isEmpty {
            dragTraceScore = 0
        } else {
            dragTraceScore = Double(validDragTraceCount) / Double(dragSamples.count)
        }

        let composite = (coverageScore * 0.5) + (reactionScore * 0.25) + (dragTraceScore * 0.25)
        return composite.clamped(to: 0...1)
    }
}
