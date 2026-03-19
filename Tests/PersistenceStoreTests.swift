import XCTest

final class PersistenceStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear all persisted state before each test
        PersistenceStore.clearHistory()
        PersistenceStore.clearSyncJobs()
        PersistenceStore.saveCoachPlan(nil)
        PersistenceStore.saveBenchmark(nil)
    }

    override func tearDown() {
        PersistenceStore.clearHistory()
        PersistenceStore.clearSyncJobs()
        PersistenceStore.saveCoachPlan(nil)
        PersistenceStore.saveBenchmark(nil)
        super.tearDown()
    }

    // MARK: - Save / load history

    func testSaveAndLoadHistory() {
        let sessions = makeSessions(count: 3)
        PersistenceStore.saveHistory(sessions)
        let loaded = PersistenceStore.loadHistory()
        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded[0].scoringPresetRawValue, sessions[0].scoringPresetRawValue)
    }

    func testEmptyStateReturnsEmptyHistory() {
        let loaded = PersistenceStore.loadHistory()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Max history cap (12 sessions)

    func testHistoryCapAt12() {
        let sessions = makeSessions(count: 20)
        PersistenceStore.saveHistory(sessions)
        let loaded = PersistenceStore.loadHistory()
        XCTAssertEqual(loaded.count, 12, "History should be capped at 12 sessions")
    }

    // MARK: - Sync job cap (80)

    func testSyncJobCapAt80() {
        let jobs = makeSyncJobs(count: 100)
        PersistenceStore.saveSyncJobs(jobs)
        let loaded = PersistenceStore.loadSyncJobs()
        XCTAssertEqual(loaded.count, 80, "Sync jobs should be capped at 80")
    }

    func testSaveAndLoadSyncJobs() {
        let jobs = makeSyncJobs(count: 5)
        PersistenceStore.saveSyncJobs(jobs)
        let loaded = PersistenceStore.loadSyncJobs()
        XCTAssertEqual(loaded.count, 5)
    }

    // MARK: - Encoding / decoding failures (graceful fallback)

    func testCorruptHistoryDataReturnsEmpty() {
        UserDefaults.standard.set(Data("not-valid-json".utf8), forKey: "steadytap.history.v1")
        let loaded = PersistenceStore.loadHistory()
        XCTAssertTrue(loaded.isEmpty, "Corrupt data should gracefully return empty array")
    }

    func testCorruptSyncJobsDataReturnsEmpty() {
        UserDefaults.standard.set(Data("{bad".utf8), forKey: "steadytap.syncjobs.v1")
        let loaded = PersistenceStore.loadSyncJobs()
        XCTAssertTrue(loaded.isEmpty, "Corrupt sync job data should gracefully return empty array")
    }

    // MARK: - Coach plan persistence

    func testSaveAndLoadCoachPlan() {
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
        let loaded = PersistenceStore.loadCoachPlan()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.focusArea, "Precision")
        XCTAssertEqual(loaded?.confidence, 0.75, accuracy: 0.001)
    }

    func testSaveNilCoachPlanClears() {
        let plan = CoachPlan.placeholder
        PersistenceStore.saveCoachPlan(plan)
        XCTAssertNotNil(PersistenceStore.loadCoachPlan())

        PersistenceStore.saveCoachPlan(nil)
        XCTAssertNil(PersistenceStore.loadCoachPlan())
    }

    // MARK: - Empty state

    func testClearHistoryRemovesAll() {
        PersistenceStore.saveHistory(makeSessions(count: 5))
        PersistenceStore.clearHistory()
        XCTAssertTrue(PersistenceStore.loadHistory().isEmpty)
    }

    func testClearSyncJobsRemovesAll() {
        PersistenceStore.saveSyncJobs(makeSyncJobs(count: 5))
        PersistenceStore.clearSyncJobs()
        XCTAssertTrue(PersistenceStore.loadSyncJobs().isEmpty)
    }

    // MARK: - Helpers

    private func makeSessions(count: Int) -> [SessionSummary] {
        (0..<count).map { i in
            let baseline = PracticeMetrics(misses: 3, rounds: 12, completionTime: 20, accidentalTouches: 1)
            let adaptive = PracticeMetrics(misses: 1, rounds: 12, completionTime: 16, accidentalTouches: 0)
            return SessionSummary(
                timestamp: Date(timeIntervalSince1970: Double(1_700_000_000 + i * 3600)),
                scoringPreset: .balanced,
                challengeIntensity: .standard,
                weeklyGoalTarget: 4,
                baseline: baseline,
                adaptive: adaptive
            )
        }
    }

    private func makeSyncJobs(count: Int) -> [SyncJob] {
        let baseline = PracticeMetrics(misses: 2, rounds: 10, completionTime: 15, accidentalTouches: 0)
        let adaptive = PracticeMetrics(misses: 0, rounds: 10, completionTime: 12, accidentalTouches: 0)
        let calibration = CalibrationResult(
            tapMeanError: 5, tapStdDev: 3, dragMeanDeviation: 4,
            averageReactionTime: 0.8, tapSampleCount: 10, dragSampleCount: 4,
            confidenceScore: 0.9
        )
        let profile = InteractionProfile(buttonScale: 1.1, gridSpacing: 14, holdDuration: 0.1, swipeThreshold: 30)
        return (0..<count).map { _ in
            let payload = SessionUploadPayload(
                userID: "test-user",
                scoringPreset: .balanced,
                challengeIntensity: .standard,
                weeklyGoalTarget: 4,
                baseline: baseline,
                adaptive: adaptive,
                calibration: calibration,
                profile: profile
            )
            return SyncJob(payload: payload)
        }
    }
}
