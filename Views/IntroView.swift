import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct IntroView: View {
    @Binding var scoringPreset: ScoringPreset
    @Binding var challengeIntensity: ChallengeIntensity
    @Binding var weeklyGoalTarget: Int
    @Binding var hapticsEnabled: Bool
    @Binding var backendMode: BackendMode
    @Binding var autoSyncEnabled: Bool
    @Binding var userID: String
    @Binding var backendBaseURL: String
    @Binding var backendAuthToken: String

    let history: [SessionSummary]
    let bestScoreDelta: Double
    let pendingSyncCount: Int
    let syncState: SyncState
    let serviceBrief: ServiceBrief?
    let reviewPack: ServiceReviewPack?
    let coachPlan: CoachPlan?
    let benchmark: BenchmarkSnapshot?
    let trendPoints: [Double]
    let weeklySessionCount: Int
    let averageScoreDelta: Double
    let streakDays: Int
    let weeklyGoalProgress: Double
    let weeklyGoalRemaining: Int
    let isWeeklyGoalMet: Bool
    let readinessScore: Int
    let readinessBand: String
    let trendDirection: String
    let trendInsight: String
    let projectedWeeklySessions: Int
    let weeklyProjectionText: String
    let localIntensityRecommendation: ChallengeIntensity
    let oldestPendingSyncAge: String
    let remoteRefreshCooldown: Int
    let isRefreshingBackend: Bool

    let onClearHistory: () -> Void
    let onClearSyncQueue: () -> Void
    let onRefreshBackend: () -> Void
    let onSyncNow: () -> Void
    let onApplyCoachPreset: () -> Void
    let onApplyLocalIntensityRecommendation: () -> Void
    let onStart: () -> Void

    @State private var appear = false
    @State private var reviewerActionStatus = "Reviewer shortcuts keep the cloud sync proof path one tap away."

    private var latestResultText: String {
        guard let latest = history.first else {
            return "No previous local runs yet. Start with calibration to create your first benchmark."
        }
        let deltaPrefix = latest.scoreDelta >= 0 ? "+" : "-"
        return "Last run (\(latest.timestamp.shortDateString)): \(deltaPrefix)\(String(format: "%.1f", abs(latest.scoreDelta))) score delta in \(latest.scoringPreset.title)."
    }

    private var weeklyGoalStatusText: String {
        if isWeeklyGoalMet {
            return "Weekly goal achieved. Keep momentum and protect consistency."
        }
        if weeklyGoalRemaining == 1 {
            return "1 session left to hit this week's goal."
        }
        return "\(weeklyGoalRemaining) sessions left to hit this week's goal."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection.staged(index: 0, appear: appear)
                flowCard.staged(index: 1, appear: appear)
                scoringCard.staged(index: 2, appear: appear)
                challengeCard.staged(index: 3, appear: appear)
                opsCard.staged(index: 4, appear: appear)
                serviceBriefCard.staged(index: 5, appear: appear)
                reviewPackCard.staged(index: 6, appear: appear)
                coachCard.staged(index: 7, appear: appear)
                momentumCard.staged(index: 8, appear: appear)
                intelligenceCard.staged(index: 9, appear: appear)
                benchmarkCard.staged(index: 10, appear: appear)
                preferencesCard.staged(index: 11, appear: appear)
                progressCard.staged(index: 12, appear: appear)

                Button("Start Calibration", action: onStart)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityHint("Begins tap and drag calibration")
                    .staged(index: 13, appear: appear)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            appear = true
        }
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.mint.opacity(0.72), AppTheme.amber.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                    .blur(radius: 7)

                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black.opacity(0.68))
            }

            Text("SteadyTap")
                .font(.system(size: 50, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Production-grade adaptive motor accessibility training with local-first resilience and cloud coaching.")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var flowCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Experience Flow")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("1. Calibrate tap and drag stability")
                    .foregroundStyle(AppTheme.textSecondary)
                Text("2. Review generated adaptive profile quality")
                    .foregroundStyle(AppTheme.textSecondary)
                Text("3. Run baseline and adaptive challenge")
                    .foregroundStyle(AppTheme.textSecondary)
                Text("4. Compare outcomes and sync to service backend")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scoringCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Scoring Policy")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Picker("Scoring Mode", selection: $scoringPreset) {
                    ForEach(ScoringPreset.allCases) { preset in
                        Text(preset.shortTitle).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                Text(scoringPreset.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var opsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Backend Ops")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Picker("Backend Mode", selection: $backendMode) {
                    ForEach(BackendMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(backendMode.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                Toggle("Auto Sync", isOn: $autoSyncEnabled)
                    .foregroundStyle(AppTheme.textSecondary)
                    .tint(AppTheme.mint)

                HStack(spacing: 10) {
                    MetricTile(title: "Pending Uploads", value: "\(pendingSyncCount)")
                    MetricTile(title: "Sync Health", value: syncState.title)
                }

                HStack(spacing: 10) {
                    MetricTile(title: "Queue Age", value: oldestPendingSyncAge)
                    MetricTile(title: "Refresh Window", value: remoteRefreshCooldown > 0 ? "\(remoteRefreshCooldown)s" : "Ready")
                }

                StatusChip(title: syncState.title, tone: syncTone(syncState))

                Text(syncState.detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textTertiary)

                HStack(spacing: 10) {
                    Button(action: onSyncNow) {
                        Label("Sync Now", systemImage: "arrow.clockwise.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.mint.opacity(0.84))

                    Button(action: onRefreshBackend) {
                        Label(isRefreshingBackend ? "Refreshing..." : "Refresh Coach", systemImage: "bolt.heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
                    .disabled(isRefreshingBackend)
                }
            }
        }
    }

    private var challengeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Challenge Intensity")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Picker("Intensity", selection: $challengeIntensity) {
                    ForEach(ChallengeIntensity.allCases) { intensity in
                        Text(intensity.shortTitle).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)

                Text(challengeIntensity.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    MetricTile(title: "Rounds", value: "\(challengeIntensity.roundCount)")
                    MetricTile(title: "Weekly Goal", value: "\(weeklyGoalTarget)")
                }

                HStack(spacing: 10) {
                    MetricTile(title: "Local Suggestion", value: localIntensityRecommendation.title)

                    Button(action: onApplyLocalIntensityRecommendation) {
                        Label(
                            localIntensityRecommendation == challengeIntensity
                                ? "Suggestion Active"
                                : "Apply Local Suggestion",
                            systemImage: "speedometer"
                        )
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
                    .disabled(localIntensityRecommendation == challengeIntensity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var coachCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Remote Coach Plan")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let coachPlan {
                    HStack(spacing: 10) {
                        MetricTile(title: "Focus", value: coachPlan.focusArea)
                        MetricTile(title: "Confidence", value: "\(coachPlan.confidencePercent)%")
                    }

                    HStack(spacing: 10) {
                        MetricTile(title: "Target Delta", value: String(format: "+%.1f", coachPlan.targetScoreDelta))
                        MetricTile(title: "Sessions/Week", value: "\(coachPlan.targetSessionsPerWeek)")
                    }

                    Text("Recommended setup: \(coachPlan.recommendedPreset.title), \(coachPlan.recommendedIntensity.title) intensity")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(coachPlan.rationale)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textTertiary)

                    if !coachPlan.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(coachPlan.actionItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Circle()
                                        .fill(AppTheme.mint.opacity(0.9))
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 6)
                                    Text(item)
                                        .font(.footnote)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                    }

                    Button(action: onApplyCoachPreset) {
                        Label("Apply Coach Setup", systemImage: "wand.and.stars")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.mint.opacity(0.86))
                } else {
                    Text("No coach plan yet. Tap refresh to generate one from local sessions.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var serviceBriefCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Brief")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let serviceBrief {
                    HStack(spacing: 10) {
                        MetricTile(title: "Schema", value: serviceBrief.reportContractSchema)
                        MetricTile(title: "Auth", value: serviceBrief.authMode)
                    }

                    HStack(spacing: 10) {
                        MetricTile(title: "Storage", value: serviceBrief.storageMode)
                        MetricTile(title: "Sessions", value: "\(serviceBrief.sessionCount)")
                    }

                    Text(serviceBrief.headline)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review Flow")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(serviceBrief.reviewFlow, id: \.self) { item in
                            briefLine(item, tone: AppTheme.mint)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("2-Minute Review")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(serviceBrief.twoMinuteReview, id: \.self) { item in
                            briefLine(item, tone: AppTheme.mint.opacity(0.8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trust Boundary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(serviceBrief.trustBoundary, id: \.self) { item in
                            briefLine(item, tone: AppTheme.amber)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Watchouts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(serviceBrief.watchouts, id: \.self) { item in
                            briefLine(item, tone: .red.opacity(0.8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Proof Assets")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(serviceBrief.proofAssets, id: \.self) { item in
                            briefLine("\(item.label) -> \(item.href)", tone: AppTheme.amber.opacity(0.85))
                        }
                    }
                } else {
                    Text("Generating service brief from the active backend path.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var momentumCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Momentum")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 10) {
                    MetricTile(title: "7-Day Sessions", value: "\(weeklySessionCount)")
                    MetricTile(title: "Current Streak", value: "\(streakDays)d")
                    MetricTile(title: "Avg Delta", value: signedScore(averageScoreDelta))
                }

                HStack(spacing: 10) {
                    MetricTile(title: "Goal Progress", value: "\(weeklySessionCount)/\(weeklyGoalTarget)")
                    MetricTile(title: "Remaining", value: "\(weeklyGoalRemaining)")
                }

                ProgressView(value: weeklyGoalProgress)
                    .tint(isWeeklyGoalMet ? AppTheme.mint : AppTheme.amber)

                Text(weeklyGoalStatusText)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                SparklineView(
                    values: trendPoints,
                    lineColor: AppTheme.mint,
                    fillColor: AppTheme.mint
                )
                .frame(height: 76)
            }
        }
    }

    private var reviewPackCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Review Pack")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let reviewPack {
                    HStack(spacing: 10) {
                        MetricTile(title: "Contract", value: reviewPack.readinessContract)
                        MetricTile(title: "Auth", value: reviewPack.authMode)
                    }

                    HStack(spacing: 10) {
                        MetricTile(title: "Uploaded Surfaces", value: "\(reviewPack.uploadedSurfaceCount)")
                        MetricTile(title: "Review Routes", value: "\(reviewPack.reviewRouteCount)")
                    }

                    Text(reviewPack.headline)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review Sequence")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(reviewPack.reviewSequence, id: \.self) { item in
                            briefLine(item, tone: AppTheme.mint)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("2-Minute Review")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(reviewPack.twoMinuteReview, id: \.self) { item in
                            briefLine(item, tone: AppTheme.mint.opacity(0.8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sync Boundary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(reviewPack.syncBoundary, id: \.self) { item in
                            briefLine(item, tone: AppTheme.amber)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Watchouts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(reviewPack.watchouts, id: \.self) { item in
                            briefLine(item, tone: .red.opacity(0.8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Proof Assets")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(reviewPack.proofAssets, id: \.self) { item in
                            briefLine("\(item.label) -> \(item.href)", tone: AppTheme.amber.opacity(0.85))
                        }
                    }

                    HStack(spacing: 10) {
                        Button("Copy Review Pack") {
                            copyReviewerText(reviewPackSnapshot, success: "Copied review pack snapshot.")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.mint.opacity(0.84))

                        Button("Copy Review Routes") {
                            copyReviewerText(reviewRouteSnapshot, success: "Copied review route checklist.")
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.amber.opacity(0.9))
                    }

                    Text(reviewerActionStatus)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("Generating review pack from the active backend path.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var benchmarkCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Benchmark Snapshot")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let benchmark {
                    HStack(spacing: 10) {
                        MetricTile(title: "Cohort", value: benchmark.cohortLabel)
                        MetricTile(title: "Percentile", value: "\(benchmark.percentile)")
                    }
                    MetricTile(
                        title: "Cohort Avg Delta",
                        value: String(format: "%.1f", benchmark.averageScoreDelta)
                    )
                } else {
                    Text("Benchmark data is unavailable. Enable backend sync and refresh.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var reviewRouteSnapshot: String {
        if let reviewPack {
            let proofRoutes = reviewPack.proofAssets.map(\.href).joined(separator: "\n")
            return [
                "Health -> /v1/health",
                "Runtime Brief -> /v1/runtime-brief",
                "Review Pack -> /v1/review-pack",
                proofRoutes,
            ]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        }

        return [
            "Health -> /v1/health",
            "Runtime Brief -> /v1/runtime-brief",
            "Review Pack -> /v1/review-pack",
        ].joined(separator: "\n")
    }

    private var reviewPackSnapshot: String {
        guard let reviewPack else {
            return "Review pack unavailable."
        }

        return [
            "Contract: \(reviewPack.readinessContract)",
            "Headline: \(reviewPack.headline)",
            "Auth: \(reviewPack.authMode)",
            "Sync Boundary:",
            reviewPack.syncBoundary.joined(separator: "\n"),
            "2-Minute Review:",
            reviewPack.twoMinuteReview.joined(separator: "\n"),
            "Proof Assets:",
            reviewPack.proofAssets.map { "\($0.label) -> \($0.href)" }.joined(separator: "\n"),
        ].joined(separator: "\n")
    }

    private func copyReviewerText(_ text: String, success: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        reviewerActionStatus = success
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        reviewerActionStatus = success
        #else
        reviewerActionStatus = "Clipboard copy is unavailable on this platform."
        #endif
    }

    private var intelligenceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Performance Intelligence")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 10) {
                    MetricTile(title: "Readiness", value: "\(readinessScore)")
                    MetricTile(title: "Band", value: readinessBand)
                    MetricTile(title: "Trend", value: trendDirection)
                }

                HStack(spacing: 10) {
                    MetricTile(title: "Projected Sessions", value: "\(projectedWeeklySessions)")
                    MetricTile(title: "Suggested Intensity", value: localIntensityRecommendation.shortTitle)
                }

                Text(trendInsight)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(weeklyProjectionText)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var preferencesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Preferences")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Toggle(isOn: $hapticsEnabled) {
                    Text("Haptic feedback")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .toggleStyle(.switch)
                .tint(AppTheme.mint)

                Stepper(value: $weeklyGoalTarget, in: 1...14) {
                    HStack {
                        Text("Weekly session goal")
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text("\(weeklyGoalTarget)")
                            .foregroundStyle(AppTheme.textPrimary)
                            .fontWeight(.semibold)
                    }
                }
                .tint(AppTheme.mint)

                LabeledContent("User ID") {
                    TextField("demo-user", text: $userID)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(AppTheme.textPrimary)
                        .steadyTapTextEntryBehavior()
                }
                .foregroundStyle(AppTheme.textSecondary)

                if backendMode == .cloudPreferred {
                    LabeledContent("API Base URL") {
                        TextField("https://api.example.com", text: $backendBaseURL)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.textPrimary)
                            .steadyTapTextEntryBehavior()
                    }
                    .foregroundStyle(AppTheme.textSecondary)

                    LabeledContent("Bearer Token") {
                        SecureField("Optional token", text: $backendAuthToken)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.textPrimary)
                            .steadyTapTextEntryBehavior()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }

                Text("All local data is stored only on-device. Cloud mode uploads only run summaries.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textTertiary)

                HStack(spacing: 10) {
                    if !history.isEmpty {
                        Button(role: .destructive, action: onClearHistory) {
                            Text("Clear History")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.9))
                    }

                    if pendingSyncCount > 0 {
                        Button(role: .destructive, action: onClearSyncQueue) {
                            Text("Clear Queue")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.9))
                    }
                }
            }
        }
    }

    private var progressCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Local Progress")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 10) {
                    MetricTile(title: "Saved Runs", value: "\(history.count)")
                    MetricTile(title: "Best Gain", value: signedScore(bestScoreDelta))
                }

                Text(latestResultText)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private func signedScore(_ value: Double) -> String {
        let magnitude = String(format: "%.1f", abs(value))
        return value >= 0 ? "+\(magnitude)" : "-\(magnitude)"
    }

    private func briefLine(_ text: String, tone: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(tone)
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func syncTone(_ state: SyncState) -> StatusChip.Tone {
        switch state {
        case .idle:
            return .neutral
        case .syncing:
            return .caution
        case .success:
            return .good
        case .failed:
            return .critical
        }
    }
}

private extension View {
    @ViewBuilder
    func steadyTapTextEntryBehavior() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
        #else
        self
        #endif
    }
}

private extension View {
    func staged(index: Int, appear: Bool) -> some View {
        self
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 22)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.85)
                    .delay(Double(index) * 0.05),
                value: appear
            )
    }
}
