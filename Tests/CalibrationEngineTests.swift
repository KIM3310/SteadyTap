import XCTest
import CoreGraphics

final class CalibrationEngineTests: XCTestCase {

    // MARK: - Tap distance mean / stddev

    func testTapMeanErrorWithKnownDistances() {
        let taps = makeTapSamples(offsets: [
            (10, 0), (0, 10), (-10, 0), (0, -10)
        ])
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [])
        // All distances are exactly 10
        XCTAssertEqual(result.tapMeanError, 10.0, accuracy: 0.01)
    }

    func testTapStdDevIsZeroForUniformDistances() {
        // All taps land exactly 5pt away
        let taps = makeTapSamples(offsets: [
            (5, 0), (5, 0), (5, 0), (5, 0)
        ])
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [])
        XCTAssertEqual(result.tapStdDev, 0.0, accuracy: 0.001)
    }

    func testTapStdDevNonZeroForVariedDistances() {
        let taps = makeTapSamples(offsets: [
            (3, 4), (0, 0), (6, 8), (0, 0)
        ])
        // distances: 5, 0, 10, 0 => mean=3.75, variance computed from these
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [])
        XCTAssertGreaterThan(result.tapStdDev, 0)
    }

    // MARK: - Drag deviation analysis

    func testDragMeanDeviationWithKnownPoints() {
        let drag = DragSample(
            points: [
                CGPoint(x: 0, y: 102),
                CGPoint(x: 10, y: 98),
                CGPoint(x: 20, y: 104),
                CGPoint(x: 30, y: 96),
                CGPoint(x: 40, y: 100),
                CGPoint(x: 50, y: 100),
                CGPoint(x: 60, y: 100),
                CGPoint(x: 70, y: 100)
            ],
            referenceY: 100,
            elapsed: 0.5
        )
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [drag])
        // deviations: 2, 2, 4, 4, 0, 0, 0, 0 => mean = 12/8 = 1.5
        XCTAssertEqual(result.dragMeanDeviation, 1.5, accuracy: 0.01)
    }

    func testDragMeanDeviationPerfectTrace() {
        let drag = DragSample(
            points: [
                CGPoint(x: 0, y: 50),
                CGPoint(x: 10, y: 50),
                CGPoint(x: 20, y: 50)
            ],
            referenceY: 50,
            elapsed: 0.3
        )
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [drag])
        XCTAssertEqual(result.dragMeanDeviation, 0.0, accuracy: 0.001)
    }

    // MARK: - Reaction time tracking

    func testAverageReactionTimeCalculation() {
        let taps = [
            TapSample(target: .zero, actual: .zero, elapsed: 0.5),
            TapSample(target: .zero, actual: .zero, elapsed: 1.0),
            TapSample(target: .zero, actual: .zero, elapsed: 1.5),
        ]
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [])
        XCTAssertEqual(result.averageReactionTime, 1.0, accuracy: 0.001)
    }

    func testAverageReactionTimeIsZeroWhenNoTaps() {
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [])
        XCTAssertEqual(result.averageReactionTime, 0.0)
    }

    // MARK: - Confidence scoring

    func testConfidenceScoreMaxCoverageWithValidData() {
        // 10 taps (max coverage) + 4 drags (max coverage), all valid reaction times, all drags >= 8 points
        let taps = (0..<10).map { _ in
            TapSample(target: CGPoint(x: 50, y: 50), actual: CGPoint(x: 55, y: 55), elapsed: 0.8)
        }
        let drags = (0..<4).map { _ in
            DragSample(
                points: (0..<10).map { CGPoint(x: CGFloat($0) * 5, y: 100) },
                referenceY: 100,
                elapsed: 0.6
            )
        }
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: drags)
        // coverageScore = (1.0*0.65) + (1.0*0.35) = 1.0
        // reactionScore = 1.0 (all in 0.12...4.0)
        // dragTraceScore = 1.0 (all >= 8 points)
        // composite = (1.0*0.5) + (1.0*0.25) + (1.0*0.25) = 1.0
        XCTAssertEqual(result.confidenceScore, 1.0, accuracy: 0.01)
    }

    func testConfidenceScoreIsZeroWithEmptyInputs() {
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [])
        XCTAssertEqual(result.confidenceScore, 0.0)
    }

    func testConfidenceScorePartialCoverage() {
        // 5 taps (half coverage), 2 drags (half coverage)
        let taps = (0..<5).map { _ in
            TapSample(target: CGPoint(x: 10, y: 10), actual: CGPoint(x: 12, y: 12), elapsed: 0.5)
        }
        let drags = (0..<2).map { _ in
            DragSample(
                points: (0..<10).map { CGPoint(x: CGFloat($0), y: 50) },
                referenceY: 50,
                elapsed: 0.4
            )
        }
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: drags)
        // tapCoverage = 0.5, dragCoverage = 0.5
        // coverageScore = (0.5*0.65) + (0.5*0.35) = 0.5
        // reactionScore = 1.0, dragTraceScore = 1.0
        // composite = (0.5*0.5) + (1.0*0.25) + (1.0*0.25) = 0.75
        XCTAssertEqual(result.confidenceScore, 0.75, accuracy: 0.01)
    }

    func testConfidenceScorePenalizesOutOfRangeReactions() {
        // All reaction times outside valid range (0.12...4.0)
        let taps = (0..<10).map { _ in
            TapSample(target: .zero, actual: CGPoint(x: 5, y: 0), elapsed: 0.05)
        }
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [])
        // tapCoverage = 1.0, dragCoverage = 0
        // coverageScore = (1.0*0.65) + (0*0.35) = 0.65
        // reactionScore = 0 (all < 0.12)
        // dragTraceScore = 0 (no drags)
        // composite = (0.65*0.5) + (0*0.25) + (0*0.25) = 0.325
        XCTAssertEqual(result.confidenceScore, 0.325, accuracy: 0.01)
    }

    // MARK: - Edge cases

    func testSingleTapSample() {
        let tap = TapSample(target: CGPoint(x: 100, y: 100), actual: CGPoint(x: 103, y: 104), elapsed: 0.6)
        let result = CalibrationEngine.summarize(tapSamples: [tap], dragSamples: [])
        XCTAssertEqual(result.tapSampleCount, 1)
        XCTAssertEqual(result.tapStdDev, 0.0, accuracy: 0.001, "Single sample should have zero stddev")
        XCTAssertGreaterThan(result.tapMeanError, 0)
    }

    func testSingleDragSample() {
        let drag = DragSample(
            points: [CGPoint(x: 0, y: 55)],
            referenceY: 50,
            elapsed: 0.3
        )
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [drag])
        XCTAssertEqual(result.dragSampleCount, 1)
        XCTAssertEqual(result.dragMeanDeviation, 5.0, accuracy: 0.01)
    }

    func testEmptyDragPointsYieldZeroDeviation() {
        let drag = DragSample(points: [], referenceY: 50, elapsed: 0.2)
        let result = CalibrationEngine.summarize(tapSamples: [], dragSamples: [drag])
        XCTAssertEqual(result.dragMeanDeviation, 0.0)
    }

    // MARK: - Adaptive profile generation

    func testAdaptiveProfileBaselineForPerfectCalibration() {
        let perfect = CalibrationResult(
            tapMeanError: 0,
            tapStdDev: 0,
            dragMeanDeviation: 0,
            averageReactionTime: 0,
            tapSampleCount: 10,
            dragSampleCount: 4,
            confidenceScore: 1.0
        )
        let profile = CalibrationEngine.generateAdaptiveProfile(from: perfect)
        // compositeSeverity = 0 => buttonScale=1.0, gridSpacing=10, holdDuration=0.05, swipeThreshold=24
        XCTAssertEqual(profile.buttonScale, 1.0, accuracy: 0.01)
        XCTAssertEqual(profile.gridSpacing, 10.0, accuracy: 0.01)
        XCTAssertEqual(profile.holdDuration, 0.05, accuracy: 0.01)
        XCTAssertEqual(profile.swipeThreshold, 24.0, accuracy: 0.01)
    }

    func testAdaptiveProfileMaxSeverity() {
        let worst = CalibrationResult(
            tapMeanError: 50,
            tapStdDev: 100,
            dragMeanDeviation: 100,
            averageReactionTime: 10.0,
            tapSampleCount: 10,
            dragSampleCount: 4,
            confidenceScore: 0.5
        )
        let profile = CalibrationEngine.generateAdaptiveProfile(from: worst)
        // All severities clamped to 1.0 => compositeSeverity = 1.0
        // buttonScale = 1.0 + 0.55 = 1.55
        // gridSpacing = 10 + 18 = 28
        // holdDuration = 0.05 + 0.45 = 0.5
        // swipeThreshold = 24 + 42 = 66
        XCTAssertEqual(profile.buttonScale, 1.55, accuracy: 0.01)
        XCTAssertEqual(profile.gridSpacing, 28.0, accuracy: 0.01)
        XCTAssertEqual(profile.holdDuration, 0.5, accuracy: 0.01)
        XCTAssertEqual(profile.swipeThreshold, 66.0, accuracy: 0.01)
    }

    // MARK: - Scoring presets

    func testScoringPresetMissFocusedWeights() {
        let weights = ScoringPreset.missFocused.weights
        XCTAssertEqual(weights.missPenalty, 12.0)
        XCTAssertEqual(weights.accidentalPenalty, 4.0)
        XCTAssertEqual(weights.timePenalty, 0.6)
        XCTAssertEqual(weights.accuracyBonus, 8.0)
    }

    func testScoringPresetBalancedWeights() {
        let weights = ScoringPreset.balanced.weights
        XCTAssertEqual(weights.missPenalty, 9.0)
        XCTAssertEqual(weights.timePenalty, 1.0)
    }

    func testScoringPresetSpeedFocusedWeights() {
        let weights = ScoringPreset.speedFocused.weights
        XCTAssertEqual(weights.missPenalty, 7.0)
        XCTAssertEqual(weights.timePenalty, 1.5)
    }

    // MARK: - Helpers

    private func makeTapSamples(offsets: [(CGFloat, CGFloat)]) -> [TapSample] {
        let target = CGPoint(x: 100, y: 100)
        return offsets.map { dx, dy in
            TapSample(
                target: target,
                actual: CGPoint(x: target.x + dx, y: target.y + dy),
                elapsed: 0.5
            )
        }
    }
}
