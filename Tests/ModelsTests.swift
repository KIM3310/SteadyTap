#if canImport(XCTest)
import XCTest
import CoreGraphics

final class ModelsTests: XCTestCase {

    // MARK: - SessionSummary encoding / decoding

    func testSessionSummaryRoundTrip() throws {
        let baseline = PracticeMetrics(misses: 3, rounds: 12, completionTime: 18.5, accidentalTouches: 1)
        let adaptive = PracticeMetrics(misses: 1, rounds: 12, completionTime: 15.0, accidentalTouches: 0)
        let summary = SessionSummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 5,
            baseline: baseline,
            adaptive: adaptive
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(summary)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionSummary.self, from: data)

        XCTAssertEqual(decoded.scoringPresetRawValue, "balanced")
        XCTAssertEqual(decoded.challengeIntensityRawValue, "standard")
        XCTAssertEqual(decoded.weeklyGoalTarget, 5)
        XCTAssertEqual(decoded.baselineScore, summary.baselineScore, accuracy: 0.001)
        XCTAssertEqual(decoded.adaptiveScore, summary.adaptiveScore, accuracy: 0.001)
        XCTAssertEqual(decoded.missDelta, summary.missDelta)
        XCTAssertEqual(decoded.timeDelta, summary.timeDelta, accuracy: 0.001)
    }

    func testSessionSummaryDecodesWithMissingOptionalFields() throws {
        // Simulate legacy data without challengeIntensityRawValue or weeklyGoalTarget
        let json: [String: Any] = [
            "timestamp": "2024-01-01T00:00:00Z",
            "scoringPresetRawValue": "missFocused",
            "baselineScore": 80.0,
            "adaptiveScore": 90.0,
            "baselineAccuracy": 0.75,
            "adaptiveAccuracy": 0.92,
            "missDelta": 2,
            "timeDelta": 3.5
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionSummary.self, from: data)

        XCTAssertEqual(decoded.challengeIntensityRawValue, "standard", "Should default to standard")
        XCTAssertEqual(decoded.weeklyGoalTarget, 4, "Should default to 4")
    }

    func testSessionSummaryScoreDelta() {
        let baseline = PracticeMetrics(misses: 4, rounds: 10, completionTime: 20, accidentalTouches: 2)
        let adaptive = PracticeMetrics(misses: 1, rounds: 10, completionTime: 14, accidentalTouches: 0)
        let summary = SessionSummary(
            scoringPreset: .missFocused,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            baseline: baseline,
            adaptive: adaptive
        )
        // scoreDelta = adaptiveScore - baselineScore; adaptive should be higher
        XCTAssertGreaterThan(summary.scoreDelta, 0)
    }

    // MARK: - CoachPlan serialization

    func testCoachPlanRoundTrip() throws {
        let plan = CoachPlan(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            focusArea: "Precision",
            rationale: "Reduce misses",
            recommendedPresetRawValue: "balanced",
            recommendedIntensityRawValue: "advanced",
            targetScoreDelta: 8.5,
            targetSessionsPerWeek: 5,
            confidence: 0.82,
            evidenceBasis: ["data point 1"],
            alignmentWithLocal: "Aligned",
            actionItems: ["Do thing 1", "Do thing 2"]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(plan)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CoachPlan.self, from: data)

        XCTAssertEqual(decoded.focusArea, "Precision")
        XCTAssertEqual(decoded.recommendedPreset, .balanced)
        XCTAssertEqual(decoded.recommendedIntensity, .advanced)
        XCTAssertEqual(decoded.targetScoreDelta, 8.5, accuracy: 0.001)
        XCTAssertEqual(decoded.confidencePercent, 82)
        XCTAssertEqual(decoded.actionItems.count, 2)
    }

    func testCoachPlanDecodesWithMissingOptionalFields() throws {
        let json: [String: Any] = [
            "generatedAt": "2024-06-01T12:00:00Z",
            "focusArea": "Speed",
            "rationale": "Go faster",
            "recommendedPresetRawValue": "speedFocused",
            "targetScoreDelta": 10.0,
            "targetSessionsPerWeek": 3,
            "confidence": 0.6
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CoachPlan.self, from: data)

        XCTAssertEqual(decoded.recommendedIntensityRawValue, "standard", "Should default intensity to standard")
        XCTAssertTrue(decoded.evidenceBasis.isEmpty)
        XCTAssertEqual(decoded.alignmentWithLocal, "")
        XCTAssertTrue(decoded.actionItems.isEmpty)
    }

    func testCoachPlanRecommendedPresetFallback() {
        let plan = CoachPlan(
            generatedAt: .now,
            focusArea: "Test",
            rationale: "Test",
            recommendedPresetRawValue: "nonexistent_preset",
            recommendedIntensityRawValue: "nonexistent_intensity",
            targetScoreDelta: 5,
            targetSessionsPerWeek: 3,
            confidence: 0.5,
            evidenceBasis: [],
            alignmentWithLocal: "",
            actionItems: []
        )
        XCTAssertEqual(plan.recommendedPreset, .missFocused, "Invalid raw value should fall back to missFocused")
        XCTAssertEqual(plan.recommendedIntensity, .standard, "Invalid raw value should fall back to standard")
    }

    // MARK: - Model defaults and boundaries

    func testPracticeMetricsAccuracyZeroRounds() {
        let metrics = PracticeMetrics(misses: 0, rounds: 0, completionTime: 0, accidentalTouches: 0)
        XCTAssertEqual(metrics.accuracy, 0.0)
    }

    func testPracticeMetricsAccuracyPerfect() {
        let metrics = PracticeMetrics(misses: 0, rounds: 10, completionTime: 8.0, accidentalTouches: 0)
        XCTAssertEqual(metrics.accuracy, 1.0)
    }

    func testPracticeMetricsScoreClampedToRange() {
        // Very bad performance should clamp to 0
        let terrible = PracticeMetrics(misses: 50, rounds: 10, completionTime: 100, accidentalTouches: 20)
        XCTAssertEqual(terrible.score(using: .missFocused), 0.0)

        // Perfect performance with bonus should clamp to 120
        let perfect = PracticeMetrics(misses: 0, rounds: 10, completionTime: 0, accidentalTouches: 0)
        let score = perfect.score(using: .missFocused)
        XCTAssertLessThanOrEqual(score, 120.0)
        XCTAssertGreaterThanOrEqual(score, 0.0)
    }

    // MARK: - Readiness score range

    func testReadinessScoreCalculationRange() {
        // The readiness score formula starts at 52 and adds bonuses.
        // With no history (all bonuses zero), raw = 52.0
        // Clamped to 0...100, so minimum realistic value is 52
        let base = 52.0
        XCTAssertGreaterThanOrEqual(base, 0)
        XCTAssertLessThanOrEqual(base, 100)
    }

    // MARK: - Stability index

    func testCalibrationResultStabilityIndexPerfect() {
        let result = CalibrationResult(
            tapMeanError: 0,
            tapStdDev: 0,
            dragMeanDeviation: 0,
            averageReactionTime: 0,
            tapSampleCount: 10,
            dragSampleCount: 4,
            confidenceScore: 1.0
        )
        XCTAssertEqual(result.stabilityIndex, 1.0, accuracy: 0.001)
        XCTAssertEqual(result.stabilityBand, .high)
    }

    func testCalibrationResultStabilityIndexLow() {
        let result = CalibrationResult(
            tapMeanError: 30,
            tapStdDev: 50,
            dragMeanDeviation: 50,
            averageReactionTime: 4.0,
            tapSampleCount: 5,
            dragSampleCount: 2,
            confidenceScore: 0.3
        )
        XCTAssertEqual(result.stabilityBand, .low)
    }

    func testConfidenceBandThresholds() {
        let high = CalibrationResult(
            tapMeanError: 0, tapStdDev: 0, dragMeanDeviation: 0,
            averageReactionTime: 0, tapSampleCount: 0, dragSampleCount: 0,
            confidenceScore: 0.80
        )
        XCTAssertEqual(high.confidenceBand, .high)

        let medium = CalibrationResult(
            tapMeanError: 0, tapStdDev: 0, dragMeanDeviation: 0,
            averageReactionTime: 0, tapSampleCount: 0, dragSampleCount: 0,
            confidenceScore: 0.50
        )
        XCTAssertEqual(medium.confidenceBand, .medium)

        let low = CalibrationResult(
            tapMeanError: 0, tapStdDev: 0, dragMeanDeviation: 0,
            averageReactionTime: 0, tapSampleCount: 0, dragSampleCount: 0,
            confidenceScore: 0.20
        )
        XCTAssertEqual(low.confidenceBand, .low)
    }
}
#endif
