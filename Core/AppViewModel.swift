import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    private static let tokenService = "com.kim.steadytap"
    private static let tokenAccount = "backend_bearer_token"
    private static let minRemoteRefreshInterval: TimeInterval = 10

    @Published private(set) var phase: AppPhase = .intro
    @Published private(set) var calibrationResult: CalibrationResult?
    @Published private(set) var adaptiveProfile: InteractionProfile = .baseline
    @Published private(set) var baselineMetrics: PracticeMetrics?
    @Published private(set) var adaptiveMetrics: PracticeMetrics?
    @Published private(set) var practiceRounds: [Int] = []
    @Published private(set) var sessionHistory: [SessionSummary] = []
    @Published private(set) var syncJobs: [SyncJob] = []
    @Published private(set) var coachPlan: CoachPlan?
    @Published private(set) var benchmark: BenchmarkSnapshot?
    @Published private(set) var syncState: SyncState = .idle
    @Published private(set) var isRefreshingBackend = false

    @Published var scoringPreset: ScoringPreset = .missFocused {
        didSet {
            persistPreferencesIfReady()
        }
    }

    @Published var challengeIntensity: ChallengeIntensity = .standard {
        didSet {
            persistPreferencesIfReady()
        }
    }

    @Published var weeklyGoalTarget: Int = 4 {
        didSet {
            let normalized = weeklyGoalTarget.clamped(to: 1...14)
            if normalized != weeklyGoalTarget {
                weeklyGoalTarget = normalized
                return
            }
            persistPreferencesIfReady()
        }
    }

    @Published var hapticsEnabled: Bool = true {
        didSet {
            HapticsManager.isEnabled = hapticsEnabled
            persistPreferencesIfReady()
        }
    }

    @Published var backendMode: BackendMode = .localOnly {
        didSet {
            persistPreferencesIfReady()
            if !isHydrating {
                scheduleRemoteInsightsRefresh(delay: 0.15)
            }
        }
    }

    @Published var autoSyncEnabled: Bool = true {
        didSet {
            persistPreferencesIfReady()
            if autoSyncEnabled && !isHydrating {
                syncNowButtonTapped()
            }
        }
    }

    @Published var userID: String = "demo-user" {
        didSet {
            persistPreferencesIfReady()
            if !isHydrating {
                scheduleRemoteInsightsRefresh(delay: 0.45)
            }
        }
    }

    @Published var backendBaseURL: String = "" {
        didSet {
            persistPreferencesIfReady()
            if backendMode == .cloudPreferred && !isHydrating {
                scheduleRemoteInsightsRefresh(delay: 0.45)
            }
        }
    }

    @Published var backendAuthToken: String = "" {
        didSet {
            persistTokenToKeychainIfReady()
            persistPreferencesIfReady()
            if backendMode == .cloudPreferred && !isHydrating {
                scheduleRemoteInsightsRefresh(delay: 0.45)
            }
        }
    }

    private var isHydrating = true
    private var isSyncRunning = false
    private var isInsightRefreshRunning = false
    private var refreshDebounceTask: Task<Void, Never>?
    private var lastRemoteRefreshAt: Date?

    init() {
        let preferences = PersistenceStore.loadPreferences()
        scoringPreset = preferences.scoringPreset
        challengeIntensity = preferences.challengeIntensity
        weeklyGoalTarget = preferences.weeklyGoalTarget.clamped(to: 1...14)
        hapticsEnabled = preferences.hapticsEnabled
        backendMode = preferences.backendMode
        autoSyncEnabled = preferences.autoSyncEnabled
        userID = preferences.userID
        backendBaseURL = preferences.backendBaseURL
        let tokenInKeychain = KeychainStore.get(
            service: Self.tokenService,
            account: Self.tokenAccount
        )
        backendAuthToken = tokenInKeychain ?? preferences.backendAuthToken
        HapticsManager.isEnabled = hapticsEnabled

        sessionHistory = PersistenceStore.loadHistory()
            .sorted(by: { $0.timestamp > $1.timestamp })
        syncJobs = PersistenceStore.loadSyncJobs()
            .sorted(by: { $0.createdAt < $1.createdAt })
        coachPlan = PersistenceStore.loadCoachPlan()
        benchmark = PersistenceStore.loadBenchmark()

        isHydrating = false
        persistTokenToKeychainIfReady()
        persistPreferencesIfReady()

        Task {
            await refreshRemoteInsights()
            if autoSyncEnabled && !syncJobs.isEmpty {
                await syncNow()
            }
        }
    }

    deinit {
        refreshDebounceTask?.cancel()
    }

    var bestScoreDelta: Double {
        sessionHistory.map(\.scoreDelta).max() ?? 0
    }

    var latestSession: SessionSummary? {
        sessionHistory.first
    }

    var pendingSyncCount: Int {
        syncJobs.count
    }

    var momentumTrendPoints: [Double] {
        let deltas = sessionHistory.prefix(12).map(\.scoreDelta)
        return Array(deltas.reversed())
    }

    var weeklySessionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        return sessionHistory.filter { $0.timestamp >= weekAgo }.count
    }

    var weeklyGoalProgress: Double {
        let target = max(1, weeklyGoalTarget)
        return (Double(weeklySessionCount) / Double(target)).clamped(to: 0...1)
    }

    var weeklyGoalRemainingSessions: Int {
        max(0, weeklyGoalTarget - weeklySessionCount)
    }

    var isWeeklyGoalMet: Bool {
        weeklyGoalRemainingSessions == 0
    }

    var averageScoreDeltaRecent: Double {
        let recent = Array(sessionHistory.prefix(8))
        guard !recent.isEmpty else {
            return 0
        }
        return recent.map(\.scoreDelta).reduce(0, +) / Double(recent.count)
    }

    var currentStreakDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.timestamp) })
        guard !uniqueDays.isEmpty else {
            return 0
        }

        var streak = 0
        var dayCursor = calendar.startOfDay(for: Date())
        while uniqueDays.contains(dayCursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayCursor) else {
                break
            }
            dayCursor = previousDay
        }
        return streak
    }

    var trendSlopeRecent: Double {
        let recentDeltas = Array(sessionHistory.prefix(6).map(\.scoreDelta).reversed())
        return Self.linearSlope(recentDeltas)
    }

    var trendDirectionTitle: String {
        switch trendSlopeRecent {
        case 0.9...:
            return "Rising"
        case ..<(-0.9):
            return "Cooling"
        default:
            return "Stable"
        }
    }

    var trendDirectionDetail: String {
        switch trendSlopeRecent {
        case 0.9...:
            return "Your score deltas are climbing. You can safely increase challenge pressure."
        case ..<(-0.9):
            return "Recent momentum dipped. Keep precision-focused sessions before increasing speed."
        default:
            return "Performance is steady. Keep cadence and maintain low accidental input."
        }
    }

    var readinessScore: Int {
        let trendBonus = trendSlopeRecent * 6.0
        let streakBonus = Double(min(currentStreakDays, 7)) * 3.2
        let goalBonus = weeklyGoalProgress * 16.0
        let deltaBonus = averageScoreDeltaRecent * 2.4
        let raw = 52.0 + trendBonus + streakBonus + goalBonus + deltaBonus
        return Int(raw.rounded()).clamped(to: 0...100)
    }

    var readinessBandTitle: String {
        switch readinessScore {
        case 80...:
            return "Prime"
        case 58..<80:
            return "Building"
        default:
            return "Recover"
        }
    }

    var localIntensityRecommendation: ChallengeIntensity {
        let recent = Array(sessionHistory.prefix(4))
        guard !recent.isEmpty else {
            return .standard
        }

        let recentDelta = recent.map(\.scoreDelta).reduce(0, +) / Double(recent.count)
        if recentDelta >= 11, trendSlopeRecent >= 0.8 {
            return .advanced
        }
        if recentDelta < 4 || trendSlopeRecent < -0.8 {
            return .supportive
        }
        return .standard
    }

    var projectedWeeklySessions: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let elapsedDays = max(1, (calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0) + 1)
        let projected = (Double(weeklySessionCount) / Double(elapsedDays)) * 7.0
        return Int(projected.rounded())
    }

    var weeklyProjectionText: String {
        let projected = projectedWeeklySessions
        if projected >= weeklyGoalTarget {
            return "Current pace projects \(projected) sessions this week. Goal is on track."
        }
        let deficit = max(1, weeklyGoalTarget - projected)
        return "Current pace projects \(projected) sessions. Add \(deficit) more this week to hit goal."
    }

    var oldestPendingSyncAgeLabel: String {
        guard let oldest = syncJobs.map(\.createdAt).min() else {
            return "0m"
        }
        let age = max(0, Int(Date().timeIntervalSince(oldest)))
        if age < 3600 {
            return "\(max(1, age / 60))m"
        }
        return "\(age / 3600)h"
    }

    var remoteRefreshCooldownRemaining: Int {
        guard let lastRemoteRefreshAt else {
            return 0
        }
        let remaining = Self.minRemoteRefreshInterval - Date().timeIntervalSince(lastRemoteRefreshAt)
        return max(0, Int(remaining.rounded(.up)))
    }

    func applyLocalIntensityRecommendation() {
        challengeIntensity = localIntensityRecommendation
    }

    func applyCoachRecommendedPreset() {
        guard let coachPlan else {
            return
        }
        scoringPreset = coachPlan.recommendedPreset
        challengeIntensity = coachPlan.recommendedIntensity
        weeklyGoalTarget = coachPlan.targetSessionsPerWeek.clamped(to: 1...14)
    }

    func startChallenge() {
        practiceRounds = Self.makePracticeRounds(count: challengeIntensity.roundCount)
        calibrationResult = nil
        baselineMetrics = nil
        adaptiveMetrics = nil
        adaptiveProfile = .baseline
        phase = .calibration
    }

    func finishCalibration(tapSamples: [TapSample], dragSamples: [DragSample]) {
        let result = CalibrationEngine.summarize(tapSamples: tapSamples, dragSamples: dragSamples)
        calibrationResult = result
        let baseProfile = CalibrationEngine.generateAdaptiveProfile(from: result)
        adaptiveProfile = challengeIntensity.tunedProfile(from: baseProfile)
        phase = .calibrationReview
    }

    func continueFromCalibrationReview() {
        phase = .baselinePractice
    }

    func redoCalibration() {
        baselineMetrics = nil
        adaptiveMetrics = nil
        phase = .calibration
    }

    func finishBaseline(_ metrics: PracticeMetrics) {
        baselineMetrics = metrics
        phase = .adaptivePractice
    }

    func finishAdaptive(_ metrics: PracticeMetrics) {
        adaptiveMetrics = metrics

        if let baselineMetrics {
            appendSessionSummary(baseline: baselineMetrics, adaptive: metrics)
            enqueueUploadJobIfPossible(baseline: baselineMetrics, adaptive: metrics)
        }

        phase = .results

        if autoSyncEnabled {
            Task {
                await syncNow()
            }
        } else {
            syncState = .idle
        }
    }

    func clearHistory() {
        sessionHistory.removeAll()
        PersistenceStore.clearHistory()
    }

    func clearSyncQueue() {
        syncJobs.removeAll()
        PersistenceStore.clearSyncJobs()
        syncState = .idle
    }

    func restart() {
        phase = .intro
    }

    func refreshRemoteInsightsButtonTapped() {
        refreshDebounceTask?.cancel()
        Task {
            await refreshRemoteInsights(force: true)
        }
    }

    func syncNowButtonTapped() {
        Task {
            await syncNow()
        }
    }

    func refreshRemoteInsights(force: Bool = false) async {
        if !force {
            let cooldown = remoteRefreshCooldownRemaining
            if cooldown > 0 {
                return
            }
        }

        guard !isInsightRefreshRunning else {
            return
        }
        isInsightRefreshRunning = true
        isRefreshingBackend = true
        lastRemoteRefreshAt = .now

        defer {
            isInsightRefreshRunning = false
            isRefreshingBackend = false
        }

        let client = makeBackendClient()
        let resolvedUserID = normalizedUserID
        do {
            async let plan = client.fetchCoachPlan(userID: resolvedUserID, history: sessionHistory)
            async let benchmark = client.fetchBenchmark(userID: resolvedUserID, history: sessionHistory)
            let (resolvedPlan, resolvedBenchmark) = try await (plan, benchmark)

            coachPlan = resolvedPlan
            self.benchmark = resolvedBenchmark
            PersistenceStore.saveCoachPlan(resolvedPlan)
            PersistenceStore.saveBenchmark(resolvedBenchmark)

            if case .failed = syncState {
                syncState = .success(.now)
            } else if case .syncing = syncState {
                // Keep syncing state while sync is running.
            } else {
                syncState = .success(.now)
            }
        } catch {
            if coachPlan == nil {
                coachPlan = .placeholder
            }
            if benchmark == nil {
                benchmark = .placeholder
            }
            syncState = .failed(error.userFacingMessage)
        }
    }

    func syncNow() async {
        guard !isSyncRunning else {
            return
        }

        isSyncRunning = true
        syncState = .syncing

        defer {
            isSyncRunning = false
        }

        guard !syncJobs.isEmpty else {
            syncState = .idle
            await refreshRemoteInsights(force: false)
            return
        }

        var unresolved: [SyncJob] = []
        let client = makeBackendClient()

        for var job in syncJobs {
            do {
                try await client.uploadSession(job.payload)
            } catch {
                job.retryCount += 1
                job.lastError = error.userFacingMessage
                unresolved.append(job)
            }
        }

        syncJobs = unresolved
        PersistenceStore.saveSyncJobs(syncJobs)

        if unresolved.isEmpty {
            syncState = .success(.now)
        } else {
            syncState = .failed("\(unresolved.count) session(s) pending upload.")
        }

        await refreshRemoteInsights(force: false)
    }

    private func enqueueUploadJobIfPossible(baseline: PracticeMetrics, adaptive: PracticeMetrics) {
        guard let calibrationResult else {
            return
        }

        let payload = SessionUploadPayload(
            userID: normalizedUserID,
            scoringPreset: scoringPreset,
            challengeIntensity: challengeIntensity,
            weeklyGoalTarget: weeklyGoalTarget,
            baseline: baseline,
            adaptive: adaptive,
            calibration: calibrationResult,
            profile: adaptiveProfile
        )

        syncJobs.append(SyncJob(payload: payload))
        PersistenceStore.saveSyncJobs(syncJobs)
    }

    private func appendSessionSummary(baseline: PracticeMetrics, adaptive: PracticeMetrics) {
        let summary = SessionSummary(
            scoringPreset: scoringPreset,
            challengeIntensity: challengeIntensity,
            weeklyGoalTarget: weeklyGoalTarget,
            baseline: baseline,
            adaptive: adaptive
        )
        sessionHistory.insert(summary, at: 0)
        PersistenceStore.saveHistory(sessionHistory)
    }

    private func persistPreferencesIfReady() {
        guard !isHydrating else {
            return
        }

        let preferences = AppPreferences(
            scoringPresetRawValue: scoringPreset.rawValue,
            challengeIntensityRawValue: challengeIntensity.rawValue,
            weeklyGoalTarget: weeklyGoalTarget,
            hapticsEnabled: hapticsEnabled,
            backendModeRawValue: backendMode.rawValue,
            autoSyncEnabled: autoSyncEnabled,
            userID: userID,
            backendBaseURL: backendBaseURL,
            backendAuthToken: ""
        )
        PersistenceStore.savePreferences(preferences)
    }

    private func scheduleRemoteInsightsRefresh(delay: TimeInterval) {
        refreshDebounceTask?.cancel()
        refreshDebounceTask = Task { [weak self] in
            let clampedDelay = max(0.05, delay)
            let delayNanos = UInt64((clampedDelay * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: delayNanos)
            guard !Task.isCancelled else {
                return
            }
            await self?.refreshRemoteInsights(force: false)
        }
    }

    private func makeBackendClient() -> SteadyTapBackendClient {
        switch backendMode {
        case .localOnly:
            return MockBackendClient()
        case .cloudPreferred:
            guard !backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let url = URL(string: backendBaseURL) else {
                return MockBackendClient()
            }
            let token = backendAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
            return CloudBackendClient(baseURL: url, token: token.isEmpty ? nil : token)
        }
    }

    private var normalizedUserID: String {
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "anonymous-user" : trimmed
    }

    private func persistTokenToKeychainIfReady() {
        guard !isHydrating else {
            return
        }

        let trimmed = backendAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.remove(service: Self.tokenService, account: Self.tokenAccount)
            return
        }

        _ = KeychainStore.set(
            value: trimmed,
            service: Self.tokenService,
            account: Self.tokenAccount
        )
    }

    private static func makePracticeRounds(count: Int) -> [Int] {
        var generator = SystemRandomNumberGenerator()
        let resolvedCount = max(6, count)
        return (0..<resolvedCount).map { _ in
            Int.random(in: 1...9, using: &generator)
        }
    }

    private static func linearSlope(_ values: [Double]) -> Double {
        guard values.count > 1 else {
            return 0
        }

        let count = Double(values.count)
        let meanX = (count - 1) / 2.0
        let meanY = values.reduce(0, +) / count

        var numerator = 0.0
        var denominator = 0.0
        for (index, value) in values.enumerated() {
            let x = Double(index)
            let dx = x - meanX
            numerator += dx * (value - meanY)
            denominator += dx * dx
        }

        guard denominator > 0 else {
            return 0
        }
        return numerator / denominator
    }
}

private extension Error {
    var userFacingMessage: String {
        if let localizedError = self as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return localizedDescription
    }
}
