import Foundation
import CoreGraphics

enum AppPhase: String {
    case intro
    case calibration
    case calibrationReview
    case baselinePractice
    case adaptivePractice
    case results

    var flowTitle: String {
        switch self {
        case .intro:
            return "Welcome"
        case .calibration:
            return "Calibration"
        case .calibrationReview:
            return "Profile Review"
        case .baselinePractice:
            return "Baseline"
        case .adaptivePractice:
            return "Adaptive"
        case .results:
            return "Results"
        }
    }

    var flowStepLabel: String? {
        switch self {
        case .intro:
            return nil
        case .calibration:
            return "Step 1 of 5"
        case .calibrationReview:
            return "Step 2 of 5"
        case .baselinePractice:
            return "Step 3 of 5"
        case .adaptivePractice:
            return "Step 4 of 5"
        case .results:
            return "Step 5 of 5"
        }
    }

    var flowProgress: Double {
        switch self {
        case .intro:
            return 0
        case .calibration:
            return 0.2
        case .calibrationReview:
            return 0.4
        case .baselinePractice:
            return 0.6
        case .adaptivePractice:
            return 0.8
        case .results:
            return 1.0
        }
    }

    var supportsFlowExit: Bool {
        self != .intro
    }
}

struct TapSample: Identifiable {
    let id = UUID()
    let target: CGPoint
    let actual: CGPoint
    let elapsed: TimeInterval

    var distance: CGFloat {
        target.distance(to: actual)
    }
}

struct DragSample: Identifiable {
    let id = UUID()
    let points: [CGPoint]
    let referenceY: CGFloat
    let elapsed: TimeInterval

    var meanDeviation: CGFloat {
        guard !points.isEmpty else {
            return 0
        }
        let total = points.reduce(CGFloat.zero) { partial, point in
            partial + abs(point.y - referenceY)
        }
        return total / CGFloat(points.count)
    }
}

struct CalibrationResult {
    let tapMeanError: CGFloat
    let tapStdDev: CGFloat
    let dragMeanDeviation: CGFloat
    let averageReactionTime: TimeInterval
    let tapSampleCount: Int
    let dragSampleCount: Int
    let confidenceScore: Double

    var stabilityIndex: Double {
        let normalizedTap = min(1.0, Double(tapStdDev / 32.0))
        let normalizedDrag = min(1.0, Double(dragMeanDeviation / 36.0))
        let normalizedReaction = min(1.0, averageReactionTime / 2.8)
        return max(0.0, 1.0 - ((normalizedTap * 0.45) + (normalizedDrag * 0.35) + (normalizedReaction * 0.20)))
    }

    var stabilityBand: StabilityBand {
        switch stabilityIndex {
        case 0.72...:
            return .high
        case 0.45..<0.72:
            return .moderate
        default:
            return .low
        }
    }

    var confidenceBand: ConfidenceBand {
        switch confidenceScore {
        case 0.75...:
            return .high
        case 0.45..<0.75:
            return .medium
        default:
            return .low
        }
    }
}

enum StabilityBand: String {
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"

    var guidance: String {
        switch self {
        case .high:
            return "Your touch stability is already strong. Adaptive mode should feel mostly similar with subtle safety margins."
        case .moderate:
            return "Your stability is mixed. Adaptive spacing and hold timing should reduce accidental interactions."
        case .low:
            return "Your profile shows high touch variance. Larger targets and stricter gesture filtering are recommended."
        }
    }
}

enum ConfidenceBand: String {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var hint: String {
        switch self {
        case .high:
            return "Calibration samples are consistent and reliable."
        case .medium:
            return "Calibration is usable. Recalibration can improve precision."
        case .low:
            return "Signal quality is weak. Recalibration is recommended."
        }
    }
}

struct InteractionProfile {
    let buttonScale: CGFloat
    let gridSpacing: CGFloat
    let holdDuration: TimeInterval
    let swipeThreshold: CGFloat

    static let baseline = InteractionProfile(
        buttonScale: 1.0,
        gridSpacing: 10,
        holdDuration: 0,
        swipeThreshold: 24
    )
}

struct ScoreWeights {
    let missPenalty: Double
    let accidentalPenalty: Double
    let timePenalty: Double
    let accuracyBonus: Double
}

enum ScoringPreset: String, CaseIterable, Identifiable, Codable {
    case missFocused
    case balanced
    case speedFocused

    var id: String { rawValue }

    var title: String {
        switch self {
        case .missFocused:
            return "Mistake-first"
        case .balanced:
            return "Balanced"
        case .speedFocused:
            return "Speed-first"
        }
    }

    var shortTitle: String {
        switch self {
        case .missFocused:
            return "Mistake"
        case .balanced:
            return "Balanced"
        case .speedFocused:
            return "Speed"
        }
    }

    var subtitle: String {
        switch self {
        case .missFocused:
            return "Prioritizes fewer misses and accidental touches over raw speed."
        case .balanced:
            return "Balances error reduction and completion speed."
        case .speedFocused:
            return "Rewards faster completion while still penalizing mistakes."
        }
    }

    var weights: ScoreWeights {
        switch self {
        case .missFocused:
            return ScoreWeights(missPenalty: 12.0, accidentalPenalty: 4.0, timePenalty: 0.6, accuracyBonus: 8.0)
        case .balanced:
            return ScoreWeights(missPenalty: 9.0, accidentalPenalty: 3.0, timePenalty: 1.0, accuracyBonus: 6.0)
        case .speedFocused:
            return ScoreWeights(missPenalty: 7.0, accidentalPenalty: 2.0, timePenalty: 1.5, accuracyBonus: 4.0)
        }
    }
}

enum ChallengeIntensity: String, CaseIterable, Identifiable, Codable {
    case supportive
    case standard
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supportive:
            return "Supportive"
        case .standard:
            return "Standard"
        case .advanced:
            return "Advanced"
        }
    }

    var shortTitle: String {
        switch self {
        case .supportive:
            return "Support"
        case .standard:
            return "Standard"
        case .advanced:
            return "Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .supportive:
            return "Extra forgiving adaptive tuning with fewer rounds."
        case .standard:
            return "Balanced challenge level for most learners."
        case .advanced:
            return "Tighter adaptive assistance with longer sessions."
        }
    }

    var roundCount: Int {
        switch self {
        case .supportive:
            return 10
        case .standard:
            return 12
        case .advanced:
            return 15
        }
    }

    private var buttonScaleMultiplier: CGFloat {
        switch self {
        case .supportive:
            return 1.08
        case .standard:
            return 1.0
        case .advanced:
            return 0.94
        }
    }

    private var holdDurationMultiplier: Double {
        switch self {
        case .supportive:
            return 1.12
        case .standard:
            return 1.0
        case .advanced:
            return 0.88
        }
    }

    private var swipeThresholdMultiplier: CGFloat {
        switch self {
        case .supportive:
            return 1.12
        case .standard:
            return 1.0
        case .advanced:
            return 0.9
        }
    }

    func tunedProfile(from profile: InteractionProfile) -> InteractionProfile {
        InteractionProfile(
            buttonScale: (profile.buttonScale * buttonScaleMultiplier).clamped(to: 1.0...1.85),
            gridSpacing: profile.gridSpacing,
            holdDuration: (profile.holdDuration * holdDurationMultiplier).clamped(to: 0.03...0.55),
            swipeThreshold: (profile.swipeThreshold * swipeThresholdMultiplier).clamped(to: 20...72)
        )
    }
}

enum BackendMode: String, CaseIterable, Identifiable, Codable {
    case localOnly
    case cloudPreferred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localOnly:
            return "Local AI"
        case .cloudPreferred:
            return "Cloud API"
        }
    }

    var subtitle: String {
        switch self {
        case .localOnly:
            return "Runs fully on-device with mock cloud analytics."
        case .cloudPreferred:
            return "Uses remote API when available and falls back locally."
        }
    }
}

enum SyncState: Equatable {
    case idle
    case syncing
    case success(Date)
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            return "Idle"
        case .syncing:
            return "Syncing"
        case .success:
            return "Healthy"
        case .failed:
            return "Needs attention"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            return "No pending network operation."
        case .syncing:
            return "Uploading sessions and refreshing remote insights."
        case .success(let date):
            return "Last successful sync: \(date.shortDateString)."
        case .failed(let message):
            return "Latest sync failed: \(message)"
        }
    }
}

struct CoachPlan: Codable {
    let generatedAt: Date
    let focusArea: String
    let rationale: String
    let recommendedPresetRawValue: String
    let recommendedIntensityRawValue: String
    let targetScoreDelta: Double
    let targetSessionsPerWeek: Int
    let confidence: Double
    let evidenceBasis: [String]
    let alignmentWithLocal: String
    let actionItems: [String]

    var recommendedPreset: ScoringPreset {
        ScoringPreset(rawValue: recommendedPresetRawValue) ?? .missFocused
    }

    var recommendedIntensity: ChallengeIntensity {
        ChallengeIntensity(rawValue: recommendedIntensityRawValue) ?? .standard
    }

    var confidencePercent: Int {
        Int((confidence.clamped(to: 0...1)) * 100)
    }

    static let placeholder = CoachPlan(
        generatedAt: .now,
        focusArea: "Demo fallback · accidental touch reduction",
        rationale: "Demo fallback: profile variance suggests adding stronger confirmation timing until the backend is reachable again.",
        recommendedPresetRawValue: ScoringPreset.missFocused.rawValue,
        recommendedIntensityRawValue: ChallengeIntensity.standard.rawValue,
        targetScoreDelta: 8,
        targetSessionsPerWeek: 4,
        confidence: 0.72,
        evidenceBasis: [
            "Recent sessions considered: 3",
            "Recent score delta baseline: 6.00",
            "Lifetime average delta: 5.50",
        ],
        alignmentWithLocal: "Remote coaching is aligned to your recent local pattern and current confidence level.",
        actionItems: [
            "Use Mistake-first preset for the next 3 sessions.",
            "Aim for less than 2 accidental touches per run.",
            "Repeat calibration if confidence stays below medium."
        ]
    )

    init(
        generatedAt: Date,
        focusArea: String,
        rationale: String,
        recommendedPresetRawValue: String,
        recommendedIntensityRawValue: String,
        targetScoreDelta: Double,
        targetSessionsPerWeek: Int,
        confidence: Double,
        evidenceBasis: [String],
        alignmentWithLocal: String,
        actionItems: [String]
    ) {
        self.generatedAt = generatedAt
        self.focusArea = focusArea
        self.rationale = rationale
        self.recommendedPresetRawValue = recommendedPresetRawValue
        self.recommendedIntensityRawValue = recommendedIntensityRawValue
        self.targetScoreDelta = targetScoreDelta
        self.targetSessionsPerWeek = targetSessionsPerWeek
        self.confidence = confidence
        self.evidenceBasis = evidenceBasis
        self.alignmentWithLocal = alignmentWithLocal
        self.actionItems = actionItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        focusArea = try container.decode(String.self, forKey: .focusArea)
        rationale = try container.decode(String.self, forKey: .rationale)
        recommendedPresetRawValue = try container.decode(String.self, forKey: .recommendedPresetRawValue)
        recommendedIntensityRawValue = try container.decodeIfPresent(String.self, forKey: .recommendedIntensityRawValue) ?? ChallengeIntensity.standard.rawValue
        targetScoreDelta = try container.decode(Double.self, forKey: .targetScoreDelta)
        targetSessionsPerWeek = try container.decode(Int.self, forKey: .targetSessionsPerWeek)
        confidence = try container.decode(Double.self, forKey: .confidence)
        evidenceBasis = try container.decodeIfPresent([String].self, forKey: .evidenceBasis) ?? []
        alignmentWithLocal = try container.decodeIfPresent(String.self, forKey: .alignmentWithLocal) ?? ""
        actionItems = try container.decodeIfPresent([String].self, forKey: .actionItems) ?? []
    }
}

struct BenchmarkSnapshot: Codable {
    let generatedAt: Date
    let cohortLabel: String
    let percentile: Int
    let averageScoreDelta: Double

    static let placeholder = BenchmarkSnapshot(
        generatedAt: .now,
        cohortLabel: "Demo fallback cohort",
        percentile: 61,
        averageScoreDelta: 6.8
    )
}

struct ServiceBrief: Codable {
    struct ProofAsset: Codable, Hashable {
        let label: String
        let href: String
    }

    let generatedAt: Date
    let readinessContract: String
    let headline: String
    let reportContractSchema: String
    let authMode: String
    let storageMode: String
    let sessionCount: Int
    let reviewFlow: [String]
    let twoMinuteReview: [String]
    let watchouts: [String]
    let trustBoundary: [String]
    let proofAssets: [ProofAsset]

    static let placeholder = ServiceBrief(
        generatedAt: .now,
        readinessContract: "steadytap-service-brief-v1",
        headline: "Demo fallback: local-first motor accessibility coaching with explicit review and upload boundaries.",
        reportContractSchema: "steadytap-coach-report-v1",
        authMode: "open-review",
        storageMode: "sqlite-local",
        sessionCount: 4,
        reviewFlow: [
            "Calibrate locally before creating a new coaching plan.",
            "Upload only run summaries when cloud sync is enabled.",
            "Refresh the remote coach after queue health is stable."
        ],
        twoMinuteReview: [
            "Open health or meta to confirm auth and storage posture.",
            "Read runtime brief for sync boundary and watchouts.",
            "Compare coach outputs against recent local sessions.",
            "Check the sync queue before trusting cloud guidance."
        ],
        watchouts: [
            "Cloud mode falls back to local coaching if the base URL or token is invalid.",
            "Only summaries are uploaded; raw tap traces stay on-device."
        ],
        trustBoundary: [
            "Calibration and adaptive profile generation run on-device.",
            "Remote coaching only receives session summaries and preference context."
        ],
        proofAssets: [
            ProofAsset(label: "Health Surface", href: "/v1/health"),
            ProofAsset(label: "Runtime Brief", href: "/v1/runtime-brief"),
            ProofAsset(label: "Review Pack", href: "/v1/review-pack"),
            ProofAsset(label: "Coach Schema", href: "/v1/schema/coach-report"),
        ]
    )
}

struct ServiceReviewPack: Codable {
    struct ProofAsset: Codable, Hashable {
        let label: String
        let href: String
    }

    let generatedAt: Date
    let readinessContract: String
    let headline: String
    let authMode: String
    let uploadedSurfaceCount: Int
    let reviewRouteCount: Int
    let reviewSequence: [String]
    let twoMinuteReview: [String]
    let syncBoundary: [String]
    let watchouts: [String]
    let proofAssets: [ProofAsset]

    static let placeholder = ServiceReviewPack(
        generatedAt: .now,
        readinessContract: "steadytap-review-pack-v1",
        headline: "Demo fallback: reviewer pack for mobile-to-cloud coaching sync and local-first fallback posture.",
        authMode: "open-review",
        uploadedSurfaceCount: 5,
        reviewRouteCount: 5,
        reviewSequence: [
            "Review health, runtime brief, and review pack before enabling cloud mode.",
            "Compare remote coach guidance against recent local sessions.",
            "Keep sync queue visible so cloud failures never hide local progress."
        ],
        twoMinuteReview: [
            "Open health or meta to confirm auth and storage posture.",
            "Read runtime brief for sync boundary and watchouts.",
            "Read review pack before enabling shared cloud testing.",
            "Compare remote coach outputs against local history."
        ],
        syncBoundary: [
            "Calibration raw traces stay on device.",
            "Uploaded payloads are limited to session summaries and adaptive profile outcomes."
        ],
        watchouts: [
            "Cloud coaching augments the app and should always have a local fallback.",
            "Sparse or stale uploads weaken remote recommendations."
        ],
        proofAssets: [
            ProofAsset(label: "Health Surface", href: "/v1/health"),
            ProofAsset(label: "Review Pack", href: "/v1/review-pack"),
            ProofAsset(label: "Coach Schema", href: "/v1/schema/coach-report"),
            ProofAsset(label: "Runtime Brief", href: "/v1/runtime-brief"),
        ]
    )
}

struct SessionUploadPayload: Identifiable, Codable {
    let id: UUID
    let userID: String
    let timestamp: Date
    let scoringPresetRawValue: String
    let baselineScore: Double
    let adaptiveScore: Double
    let missDelta: Int
    let timeDelta: Double
    let stabilityIndex: Double
    let confidenceScore: Double
    let buttonScale: Double
    let holdDuration: Double
    let swipeThreshold: Double
    let challengeIntensityRawValue: String
    let weeklyGoalTarget: Int

    init(
        userID: String,
        timestamp: Date = .now,
        scoringPreset: ScoringPreset,
        challengeIntensity: ChallengeIntensity,
        weeklyGoalTarget: Int,
        baseline: PracticeMetrics,
        adaptive: PracticeMetrics,
        calibration: CalibrationResult,
        profile: InteractionProfile
    ) {
        self.id = UUID()
        self.userID = userID
        self.timestamp = timestamp
        self.scoringPresetRawValue = scoringPreset.rawValue
        self.baselineScore = baseline.score(using: scoringPreset)
        self.adaptiveScore = adaptive.score(using: scoringPreset)
        self.missDelta = baseline.misses - adaptive.misses
        self.timeDelta = baseline.completionTime - adaptive.completionTime
        self.stabilityIndex = calibration.stabilityIndex
        self.confidenceScore = calibration.confidenceScore
        self.buttonScale = profile.buttonScale
        self.holdDuration = profile.holdDuration
        self.swipeThreshold = profile.swipeThreshold
        self.challengeIntensityRawValue = challengeIntensity.rawValue
        self.weeklyGoalTarget = weeklyGoalTarget
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userID = try container.decode(String.self, forKey: .userID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        scoringPresetRawValue = try container.decode(String.self, forKey: .scoringPresetRawValue)
        baselineScore = try container.decode(Double.self, forKey: .baselineScore)
        adaptiveScore = try container.decode(Double.self, forKey: .adaptiveScore)
        missDelta = try container.decode(Int.self, forKey: .missDelta)
        timeDelta = try container.decode(Double.self, forKey: .timeDelta)
        stabilityIndex = try container.decode(Double.self, forKey: .stabilityIndex)
        confidenceScore = try container.decode(Double.self, forKey: .confidenceScore)
        buttonScale = try container.decode(Double.self, forKey: .buttonScale)
        holdDuration = try container.decode(Double.self, forKey: .holdDuration)
        swipeThreshold = try container.decode(Double.self, forKey: .swipeThreshold)
        challengeIntensityRawValue = try container.decodeIfPresent(String.self, forKey: .challengeIntensityRawValue) ?? ChallengeIntensity.standard.rawValue
        weeklyGoalTarget = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalTarget) ?? 4
    }
}

struct SyncJob: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var retryCount: Int
    var lastError: String?
    let payload: SessionUploadPayload

    init(payload: SessionUploadPayload) {
        self.id = UUID()
        self.createdAt = .now
        self.retryCount = 0
        self.lastError = nil
        self.payload = payload
    }
}

struct SessionSummary: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let scoringPresetRawValue: String
    let baselineScore: Double
    let adaptiveScore: Double
    let baselineAccuracy: Double
    let adaptiveAccuracy: Double
    let missDelta: Int
    let timeDelta: TimeInterval
    let challengeIntensityRawValue: String
    let weeklyGoalTarget: Int

    var scoreDelta: Double {
        adaptiveScore - baselineScore
    }

    var scoringPreset: ScoringPreset {
        ScoringPreset(rawValue: scoringPresetRawValue) ?? .missFocused
    }

    var challengeIntensity: ChallengeIntensity {
        ChallengeIntensity(rawValue: challengeIntensityRawValue) ?? .standard
    }

    init(
        timestamp: Date = Date(),
        scoringPreset: ScoringPreset,
        challengeIntensity: ChallengeIntensity,
        weeklyGoalTarget: Int,
        baseline: PracticeMetrics,
        adaptive: PracticeMetrics
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.scoringPresetRawValue = scoringPreset.rawValue
        self.baselineScore = baseline.score(using: scoringPreset)
        self.adaptiveScore = adaptive.score(using: scoringPreset)
        self.baselineAccuracy = baseline.accuracy
        self.adaptiveAccuracy = adaptive.accuracy
        self.missDelta = baseline.misses - adaptive.misses
        self.timeDelta = baseline.completionTime - adaptive.completionTime
        self.challengeIntensityRawValue = challengeIntensity.rawValue
        self.weeklyGoalTarget = weeklyGoalTarget
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        scoringPresetRawValue = try container.decode(String.self, forKey: .scoringPresetRawValue)
        baselineScore = try container.decode(Double.self, forKey: .baselineScore)
        adaptiveScore = try container.decode(Double.self, forKey: .adaptiveScore)
        baselineAccuracy = try container.decode(Double.self, forKey: .baselineAccuracy)
        adaptiveAccuracy = try container.decode(Double.self, forKey: .adaptiveAccuracy)
        missDelta = try container.decode(Int.self, forKey: .missDelta)
        timeDelta = try container.decode(TimeInterval.self, forKey: .timeDelta)
        challengeIntensityRawValue = try container.decodeIfPresent(String.self, forKey: .challengeIntensityRawValue) ?? ChallengeIntensity.standard.rawValue
        weeklyGoalTarget = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalTarget) ?? 4
    }
}

struct AppPreferences: Codable {
    var scoringPresetRawValue: String
    var challengeIntensityRawValue: String
    var weeklyGoalTarget: Int
    var hapticsEnabled: Bool
    var backendModeRawValue: String
    var autoSyncEnabled: Bool
    var userID: String
    var backendBaseURL: String

    static let `default` = AppPreferences(
        scoringPresetRawValue: ScoringPreset.missFocused.rawValue,
        challengeIntensityRawValue: ChallengeIntensity.standard.rawValue,
        weeklyGoalTarget: 4,
        hapticsEnabled: true,
        backendModeRawValue: BackendMode.localOnly.rawValue,
        autoSyncEnabled: true,
        userID: "demo-user",
        backendBaseURL: ""
    )

    var scoringPreset: ScoringPreset {
        get { ScoringPreset(rawValue: scoringPresetRawValue) ?? .missFocused }
        set { scoringPresetRawValue = newValue.rawValue }
    }

    var challengeIntensity: ChallengeIntensity {
        get { ChallengeIntensity(rawValue: challengeIntensityRawValue) ?? .standard }
        set { challengeIntensityRawValue = newValue.rawValue }
    }

    var backendMode: BackendMode {
        get { BackendMode(rawValue: backendModeRawValue) ?? .localOnly }
        set { backendModeRawValue = newValue.rawValue }
    }

    init(
        scoringPresetRawValue: String,
        challengeIntensityRawValue: String,
        weeklyGoalTarget: Int,
        hapticsEnabled: Bool,
        backendModeRawValue: String,
        autoSyncEnabled: Bool,
        userID: String,
        backendBaseURL: String
    ) {
        self.scoringPresetRawValue = scoringPresetRawValue
        self.challengeIntensityRawValue = challengeIntensityRawValue
        self.weeklyGoalTarget = weeklyGoalTarget
        self.hapticsEnabled = hapticsEnabled
        self.backendModeRawValue = backendModeRawValue
        self.autoSyncEnabled = autoSyncEnabled
        self.userID = userID
        self.backendBaseURL = backendBaseURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.scoringPresetRawValue = try container.decodeIfPresent(String.self, forKey: .scoringPresetRawValue) ?? ScoringPreset.missFocused.rawValue
        self.challengeIntensityRawValue = try container.decodeIfPresent(String.self, forKey: .challengeIntensityRawValue) ?? ChallengeIntensity.standard.rawValue
        self.weeklyGoalTarget = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalTarget) ?? 4
        self.hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        self.backendModeRawValue = try container.decodeIfPresent(String.self, forKey: .backendModeRawValue) ?? BackendMode.localOnly.rawValue
        self.autoSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoSyncEnabled) ?? true
        self.userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? "demo-user"
        self.backendBaseURL = try container.decodeIfPresent(String.self, forKey: .backendBaseURL) ?? ""
    }
}

struct PracticeMetrics {
    let misses: Int
    let rounds: Int
    let completionTime: TimeInterval
    let accidentalTouches: Int

    var accuracy: Double {
        guard rounds > 0 else {
            return 0
        }
        let correct = max(0, rounds - misses)
        return Double(correct) / Double(rounds)
    }

    func score(using preset: ScoringPreset) -> Double {
        let weights = preset.weights
        let weightedMissPenalty = Double(misses) * weights.missPenalty
        let weightedAccidentalPenalty = Double(accidentalTouches) * weights.accidentalPenalty
        let weightedTimePenalty = completionTime * weights.timePenalty
        let weightedAccuracyBonus = accuracy * weights.accuracyBonus

        let rawScore = 100.0 + weightedAccuracyBonus - weightedMissPenalty - weightedAccidentalPenalty - weightedTimePenalty
        return rawScore.clamped(to: 0...120)
    }

    var score: Double {
        score(using: .missFocused)
    }
}
