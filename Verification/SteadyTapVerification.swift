import CoreGraphics
import Foundation

@main
struct SteadyTapVerification {
    static func main() throws {
        try verifyCalibrationEngine()
        try verifyModelRoundTrips()
        try verifyPersistenceStore()
        try verifyQuickStartContent()
        print("SteadyTap verification OK")
    }

    private static func verifyCalibrationEngine() throws {
        let taps = [
            TapSample(target: .zero, actual: CGPoint(x: 10, y: 0), elapsed: 0.5),
            TapSample(target: .zero, actual: CGPoint(x: 0, y: 10), elapsed: 1.0),
            TapSample(target: .zero, actual: CGPoint(x: -10, y: 0), elapsed: 1.5),
            TapSample(target: .zero, actual: CGPoint(x: 0, y: -10), elapsed: 2.0),
        ]
        let drag = DragSample(
            points: [
                CGPoint(x: 0, y: 102),
                CGPoint(x: 10, y: 98),
                CGPoint(x: 20, y: 104),
                CGPoint(x: 30, y: 96),
            ],
            referenceY: 100,
            elapsed: 0.4
        )
        let result = CalibrationEngine.summarize(tapSamples: taps, dragSamples: [drag])
        try expectNear(result.tapMeanError, 10.0, accuracy: 0.01, "tap mean error")
        try expectNear(result.averageReactionTime, 1.25, accuracy: 0.001, "average reaction time")
        try expect(result.dragMeanDeviation > 0, "drag mean deviation should be positive")

        let profile = CalibrationEngine.generateAdaptiveProfile(
            from: CalibrationResult(
                tapMeanError: 50,
                tapStdDev: 100,
                dragMeanDeviation: 100,
                averageReactionTime: 10,
                tapSampleCount: 10,
                dragSampleCount: 4,
                confidenceScore: 0.5
            )
        )
        try expectNear(profile.buttonScale, 1.55, accuracy: 0.01, "max-severity button scale")
        try expectNear(profile.gridSpacing, 28.0, accuracy: 0.01, "max-severity grid spacing")
    }

    private static func verifyModelRoundTrips() throws {
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
        let summaryData = try encoder.encode(summary)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSummary = try decoder.decode(SessionSummary.self, from: summaryData)
        try expect(decodedSummary.scoringPresetRawValue == "balanced", "session summary preset round-trip")
        try expect(decodedSummary.weeklyGoalTarget == 5, "session summary weekly goal round-trip")

        let legacySummaryJSON: [String: Any] = [
            "timestamp": "2024-01-01T00:00:00Z",
            "scoringPresetRawValue": "missFocused",
            "baselineScore": 80.0,
            "adaptiveScore": 90.0,
            "baselineAccuracy": 0.75,
            "adaptiveAccuracy": 0.92,
            "missDelta": 2,
            "timeDelta": 3.5
        ]
        let legacySummaryData = try JSONSerialization.data(withJSONObject: legacySummaryJSON)
        let decodedLegacySummary = try decoder.decode(SessionSummary.self, from: legacySummaryData)
        try expect(decodedLegacySummary.challengeIntensityRawValue == "standard", "legacy summary default intensity")
        try expect(decodedLegacySummary.weeklyGoalTarget == 4, "legacy summary default weekly goal")

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
        let planData = try encoder.encode(plan)
        let decodedPlan = try decoder.decode(CoachPlan.self, from: planData)
        try expect(decodedPlan.recommendedPreset == .balanced, "coach plan preset round-trip")
        try expect(decodedPlan.recommendedIntensity == .advanced, "coach plan intensity round-trip")

        let fallbackPlan = CoachPlan(
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
        try expect(fallbackPlan.recommendedPreset == .missFocused, "coach plan preset fallback")
        try expect(fallbackPlan.recommendedIntensity == .standard, "coach plan intensity fallback")
    }

    private static func verifyPersistenceStore() throws {
        PersistenceStore.clearHistory()
        PersistenceStore.clearSyncJobs()
        PersistenceStore.saveCoachPlan(nil)
        PersistenceStore.saveBenchmark(nil)

        let sessions = (0..<20).map { i in
            SessionSummary(
                timestamp: Date(timeIntervalSince1970: Double(1_700_000_000 + i * 3600)),
                scoringPreset: .balanced,
                challengeIntensity: .standard,
                weeklyGoalTarget: 4,
                baseline: PracticeMetrics(misses: 3, rounds: 12, completionTime: 20, accidentalTouches: 1),
                adaptive: PracticeMetrics(misses: 1, rounds: 12, completionTime: 16, accidentalTouches: 0)
            )
        }
        PersistenceStore.saveHistory(sessions)
        try expect(PersistenceStore.loadHistory().count == 12, "history cap")

        UserDefaults.standard.set(Data("not-valid-json".utf8), forKey: "steadytap.history.v1")
        try expect(PersistenceStore.loadHistory().isEmpty, "corrupt history fallback")

        let plan = CoachPlan(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            focusArea: "Precision",
            rationale: "Test rationale",
            recommendedPresetRawValue: "balanced",
            recommendedIntensityRawValue: "standard",
            targetScoreDelta: 7.0,
            targetSessionsPerWeek: 4,
            confidence: 0.75,
            evidenceBasis: ["evidence"],
            alignmentWithLocal: "aligned",
            actionItems: ["action"]
        )
        PersistenceStore.saveCoachPlan(plan)
        let loadedPlan = PersistenceStore.loadCoachPlan()
        try expect(loadedPlan?.focusArea == "Precision", "coach plan persistence")

        PersistenceStore.clearHistory()
        PersistenceStore.clearSyncJobs()
        PersistenceStore.saveCoachPlan(nil)
        PersistenceStore.saveBenchmark(nil)
    }

    private static func verifyQuickStartContent() throws {
        let plan = CoachPlan(
            generatedAt: .now,
            focusArea: "Accidental touch reduction",
            rationale: "Keep misses low.",
            recommendedPresetRawValue: ScoringPreset.missFocused.rawValue,
            recommendedIntensityRawValue: ChallengeIntensity.supportive.rawValue,
            targetScoreDelta: 6,
            targetSessionsPerWeek: 5,
            confidence: 0.8,
            evidenceBasis: [],
            alignmentWithLocal: "",
            actionItems: []
        )

        let coach = IntroQuickStartContent(
            coachPlan: plan,
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            localIntensityRecommendation: .advanced,
            readinessBand: "Prime",
            weeklyGoalStatusText: "1 session left to hit this week's goal.",
            latestResultText: "Last run today"
        )
        try expect(coach.recommendationLabel == "Apply Coach Setup", "coach recommendation label")
        try expect(coach.firstUsePromise.contains("calibration only"), "coach quick-start promise")
        try expect(coach.reviewerSafetyNote.contains("cloud sync"), "coach safety note")
        try expect(coach.routeChips[0] == "Setup · Apply coach preset", "coach route chip")

        let local = IntroQuickStartContent(
            coachPlan: nil,
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            localIntensityRecommendation: .standard,
            readinessBand: "Building",
            weeklyGoalStatusText: "Weekly goal achieved. Keep momentum and protect consistency.",
            latestResultText: "No previous local runs yet."
        )
        try expect(local.recommendationDisabled, "local recommendation disabled when already active")
        try expect(local.firstUsePromise.contains("calm calibration pass"), "local quick-start promise")
        try expect(local.routeChips[2] == "Review · Keep cloud optional", "local review chip")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() {
            throw VerificationError(message: message)
        }
    }

    private static func expectNear(_ actual: CGFloat, _ expected: CGFloat, accuracy: CGFloat, _ message: String) throws {
        if abs(actual - expected) > accuracy {
            throw VerificationError(message: "\(message): expected \(expected), got \(actual)")
        }
    }

    private static func expectNear(_ actual: Double, _ expected: Double, accuracy: Double, _ message: String) throws {
        if abs(actual - expected) > accuracy {
            throw VerificationError(message: "\(message): expected \(expected), got \(actual)")
        }
    }
}

private struct VerificationError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
