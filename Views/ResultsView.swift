import SwiftUI

struct ResultsView: View {
    let calibration: CalibrationResult
    let profile: InteractionProfile
    let scoringPreset: ScoringPreset
    let challengeIntensity: ChallengeIntensity
    let baseline: PracticeMetrics
    let adaptive: PracticeMetrics
    let history: [SessionSummary]
    let weeklySessionCount: Int
    let weeklyGoalTarget: Int
    let weeklyGoalProgress: Double
    let readinessScore: Int
    let trendDirectionTitle: String
    let localIntensityRecommendation: ChallengeIntensity
    let pendingSyncCount: Int
    let syncState: SyncState
    let bestScoreDelta: Double
    let coachPlan: CoachPlan?
    let onApplyCoachPreset: () -> Void
    let onSyncNow: () -> Void
    let onRestart: () -> Void
    @State private var appear = false

    private var baselineScore: Double {
        baseline.score(using: scoringPreset)
    }

    private var adaptiveScore: Double {
        adaptive.score(using: scoringPreset)
    }

    private var missDelta: Int {
        baseline.misses - adaptive.misses
    }

    private var timeDelta: TimeInterval {
        baseline.completionTime - adaptive.completionTime
    }

    private var scoreDelta: Double {
        adaptiveScore - baselineScore
    }

    private var accuracyDeltaPercent: Double {
        (adaptive.accuracy - baseline.accuracy) * 100
    }

    private var recentHistory: [SessionSummary] {
        Array(history.prefix(3))
    }

    private var performanceSummaryText: String {
        InsightsEngine.performanceSummary(
            baseline: baseline,
            adaptive: adaptive,
            scoringPreset: scoringPreset
        )
    }

    private var weeklyGoalRemaining: Int {
        max(0, weeklyGoalTarget - weeklySessionCount)
    }

    private var isWeeklyGoalMet: Bool {
        weeklyGoalRemaining == 0
    }

    private var profileRecommendationText: String {
        InsightsEngine.profileRecommendation(
            calibration: calibration,
            profile: profile
        )
    }

    private var shareSummary: String {
        """
        SteadyTap result
        Mode: \(scoringPreset.title)
        Intensity: \(challengeIntensity.title)
        Baseline: \(String(format: "%.1f", baselineScore))
        Adaptive: \(String(format: "%.1f", adaptiveScore))
        Score delta: \(signedDouble(scoreDelta))
        Miss delta: \(signedInt(missDelta))
        Time delta: \(signedTime(timeDelta))
        Weekly goal: \(weeklySessionCount)/\(weeklyGoalTarget)
        Sync state: \(syncState.title)
        """
    }

    private var performanceGrade: String {
        switch scoreDelta {
        case 16...:
            return "S"
        case 10..<16:
            return "A"
        case 4..<10:
            return "B"
        case 0..<4:
            return "C"
        default:
            return "D"
        }
    }

    private var isNewBest: Bool {
        scoreDelta > 0 && scoreDelta >= bestScoreDelta
    }

    private var localPrescriptionText: String {
        "Local model suggests \(localIntensityRecommendation.title) intensity next, based on your \(trendDirectionTitle.lowercased()) trend and recent execution quality."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Result Summary")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .staged(index: 0, appear: appear)

                Text("Adaptive settings were generated from your calibration and compared against baseline controls.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .staged(index: 1, appear: appear)

                GlassCard {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            MetricTile(title: "Scoring Mode", value: scoringPreset.title)
                            MetricTile(title: "Intensity", value: challengeIntensity.title)
                        }

                        HStack(spacing: 10) {
                            MetricTile(title: "Baseline Score", value: String(format: "%.1f", baselineScore))
                            MetricTile(title: "Adaptive Score", value: String(format: "%.1f", adaptiveScore))
                        }

                        HStack(spacing: 10) {
                            MetricTile(title: "Miss Delta", value: signedInt(missDelta))
                            MetricTile(title: "Time Delta", value: signedTime(timeDelta))
                        }

                        HStack(spacing: 10) {
                            MetricTile(title: "Accuracy Delta", value: signedPercent(accuracyDeltaPercent))
                            MetricTile(title: "Score Delta", value: signedDouble(scoreDelta))
                        }
                    }
                }
                .staged(index: 2, appear: appear)

                GlassCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.mint.opacity(0.95), AppTheme.amber.opacity(0.92)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 74, height: 74)
                            Text(performanceGrade)
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundStyle(.black.opacity(0.76))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Grade")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("This run delivered a \(performanceGrade) grade based on score gain and accuracy change.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)

                            if isNewBest {
                                StatusChip(title: "New Personal Best", tone: .good)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 3, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visual Comparison")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        ComparisonBar(
                            title: "Score",
                            baseline: baselineScore,
                            adaptive: adaptiveScore,
                            baselineColor: AppTheme.coral,
                            adaptiveColor: AppTheme.mint,
                            formatter: { String(format: "%.1f", $0) }
                        )

                        ComparisonBar(
                            title: "Accuracy",
                            baseline: baseline.accuracy * 100,
                            adaptive: adaptive.accuracy * 100,
                            baselineColor: AppTheme.coral.opacity(0.85),
                            adaptiveColor: AppTheme.mint.opacity(0.9),
                            formatter: { String(format: "%.1f%%", $0) }
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 4, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Coach Insight")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(performanceSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text(profileRecommendationText)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 5, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Session Intelligence")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 10) {
                            MetricTile(title: "Readiness", value: "\(readinessScore)")
                            MetricTile(title: "Trend", value: trendDirectionTitle)
                            MetricTile(title: "Local Next", value: localIntensityRecommendation.shortTitle)
                        }

                        Text(localPrescriptionText)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 6, appear: appear)

                if let coachPlan {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Next Best Action")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Coach suggests \(coachPlan.recommendedPreset.title) to optimize your next session.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text("Recommended intensity: \(coachPlan.recommendedIntensity.title) | Weekly target: \(coachPlan.targetSessionsPerWeek) sessions")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textTertiary)

                            Button(action: onApplyCoachPreset) {
                                Label("Apply Coach Setup", systemImage: "wand.and.stars.inverse")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.mint.opacity(0.86))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .staged(index: 7, appear: appear)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Adaptive Profile")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        statLine(label: "Stability band", value: calibration.stabilityBand.rawValue)
                        statLine(label: "Button scale", value: String(format: "%.2fx", profile.buttonScale))
                        statLine(label: "Grid spacing", value: "\(Int(profile.gridSpacing)) pt")
                        statLine(label: "Hold duration", value: String(format: "%.2fs", profile.holdDuration))
                        statLine(label: "Swipe threshold", value: "\(Int(profile.swipeThreshold)) pt")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 8, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calibration Snapshot")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        statLine(label: "Tap mean error", value: String(format: "%.1f pt", calibration.tapMeanError))
                        statLine(label: "Tap std. deviation", value: String(format: "%.1f pt", calibration.tapStdDev))
                        statLine(label: "Drag mean deviation", value: String(format: "%.1f pt", calibration.dragMeanDeviation))
                        statLine(label: "Reaction time", value: calibration.averageReactionTime.asSecondsString)
                        statLine(label: "Stability index", value: String(format: "%.0f / 100", calibration.stabilityIndex * 100.0))
                        statLine(label: "Confidence", value: calibration.confidenceBand.rawValue)
                        statLine(label: "Tap sample count", value: "\(calibration.tapSampleCount)")
                        statLine(label: "Drag sample count", value: "\(calibration.dragSampleCount)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 9, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sync Delivery")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 10) {
                            MetricTile(title: "Pending Uploads", value: "\(pendingSyncCount)")
                            MetricTile(title: "Health", value: syncState.title)
                        }

                        Text(syncState.detail)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textTertiary)

                        if pendingSyncCount > 0 {
                            Button(action: onSyncNow) {
                                Label("Retry Upload", systemImage: "arrow.clockwise.circle")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.mint.opacity(0.82))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 10, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekly Goal")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 10) {
                            MetricTile(title: "Progress", value: "\(weeklySessionCount)/\(weeklyGoalTarget)")
                            MetricTile(title: "Remaining", value: "\(weeklyGoalRemaining)")
                        }

                        ProgressView(value: weeklyGoalProgress)
                            .tint(isWeeklyGoalMet ? AppTheme.mint : AppTheme.amber)

                        Text(
                            isWeeklyGoalMet
                                ? "Goal met this week. Stay consistent to lock in adaptation gains."
                                : "\(weeklyGoalRemaining) more session(s) needed to hit this week's target."
                        )
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 11, appear: appear)

                if !recentHistory.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Local Runs")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            ForEach(recentHistory) { item in
                                HStack {
                                    Text(item.timestamp.shortDateString)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    Text(item.scoringPreset.shortTitle)
                                        .foregroundStyle(AppTheme.textTertiary)
                                    Text(signedDouble(item.scoreDelta))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                .font(.footnote)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .staged(index: 12, appear: appear)
                }

                HStack(spacing: 10) {
                    ShareLink(item: shareSummary) {
                        Label("Share Result", systemImage: "square.and.arrow.up")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.white.opacity(0.14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }

                    Button("Run Again", action: onRestart)
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
                .staged(index: 13, appear: appear)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .onAppear {
            appear = true
        }
    }

    private func statLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func signedInt(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func signedPercent(_ value: Double) -> String {
        let magnitude = String(format: "%.1f%%", abs(value))
        return value >= 0 ? "+\(magnitude)" : "-\(magnitude)"
    }

    private func signedTime(_ value: TimeInterval) -> String {
        let magnitude = String(format: "%.2fs", abs(value))
        return value >= 0 ? "+\(magnitude)" : "-\(magnitude)"
    }

    private func signedDouble(_ value: Double) -> String {
        let magnitude = String(format: "%.1f", abs(value))
        return value >= 0 ? "+\(magnitude)" : "-\(magnitude)"
    }
}

private extension View {
    func staged(index: Int, appear: Bool) -> some View {
        self
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.86)
                    .delay(Double(index) * 0.06),
                value: appear
            )
    }
}
