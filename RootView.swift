import SwiftUI

struct RootView: View {
    @StateObject private var model = AppViewModel()
    @State private var showExitConfirmation = false

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScreenContainer {
                VStack(spacing: 14) {
                    if model.phase.supportsFlowExit {
                        FlowHeader(
                            phase: model.phase,
                            onExitTapped: { showExitConfirmation = true }
                        )
                    }

                    contentView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .animation(.easeInOut(duration: 0.25), value: model.phase)
            }
        }
        .alert(
            "Exit current run?",
            isPresented: $showExitConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive, action: model.restart)
        } message: {
            Text("Current progress in calibration or challenge will be discarded.")
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch model.phase {
        case .intro:
            introView
        case .calibration:
            CalibrationFlowView { tapSamples, dragSamples in
                model.finishCalibration(tapSamples: tapSamples, dragSamples: dragSamples)
            }
        case .calibrationReview:
            if let calibration = model.calibrationResult {
                CalibrationReviewView(
                    calibration: calibration,
                    profile: model.adaptiveProfile,
                    onContinue: model.continueFromCalibrationReview,
                    onRecalibrate: model.redoCalibration
                )
            } else {
                introView
            }
        case .baselinePractice:
            PracticeView(
                mode: .baseline,
                intensity: model.challengeIntensity,
                profile: .baseline,
                rounds: model.practiceRounds,
                onComplete: model.finishBaseline
            )
        case .adaptivePractice:
            PracticeView(
                mode: .adaptive,
                intensity: model.challengeIntensity,
                profile: model.adaptiveProfile,
                rounds: model.practiceRounds,
                onComplete: model.finishAdaptive
            )
        case .results:
            if let calibration = model.calibrationResult,
               let baseline = model.baselineMetrics,
               let adaptive = model.adaptiveMetrics {
                ResultsView(
                    calibration: calibration,
                    profile: model.adaptiveProfile,
                    scoringPreset: model.scoringPreset,
                    challengeIntensity: model.challengeIntensity,
                    baseline: baseline,
                    adaptive: adaptive,
                    history: model.sessionHistory,
                    weeklySessionCount: model.weeklySessionCount,
                    weeklyGoalTarget: model.weeklyGoalTarget,
                    weeklyGoalProgress: model.weeklyGoalProgress,
                    readinessScore: model.readinessScore,
                    trendDirectionTitle: model.trendDirectionTitle,
                    localIntensityRecommendation: model.localIntensityRecommendation,
                    pendingSyncCount: model.pendingSyncCount,
                    syncState: model.syncState,
                    bestScoreDelta: model.bestScoreDelta,
                    coachPlan: model.coachPlan,
                    onApplyCoachPreset: model.applyCoachRecommendedPreset,
                    onSyncNow: model.syncNowButtonTapped,
                    onRestart: model.restart
                )
            } else {
                introView
            }
        }
    }

    private var introView: some View {
        IntroView(
            scoringPreset: $model.scoringPreset,
            challengeIntensity: $model.challengeIntensity,
            weeklyGoalTarget: $model.weeklyGoalTarget,
            hapticsEnabled: $model.hapticsEnabled,
            backendMode: $model.backendMode,
            autoSyncEnabled: $model.autoSyncEnabled,
            userID: $model.userID,
            backendBaseURL: $model.backendBaseURL,
            backendAuthToken: $model.backendAuthToken,
            history: model.sessionHistory,
            bestScoreDelta: model.bestScoreDelta,
            pendingSyncCount: model.pendingSyncCount,
            syncState: model.syncState,
            coachPlan: model.coachPlan,
            benchmark: model.benchmark,
            trendPoints: model.momentumTrendPoints,
            weeklySessionCount: model.weeklySessionCount,
            averageScoreDelta: model.averageScoreDeltaRecent,
            streakDays: model.currentStreakDays,
            weeklyGoalProgress: model.weeklyGoalProgress,
            weeklyGoalRemaining: model.weeklyGoalRemainingSessions,
            isWeeklyGoalMet: model.isWeeklyGoalMet,
            readinessScore: model.readinessScore,
            readinessBand: model.readinessBandTitle,
            trendDirection: model.trendDirectionTitle,
            trendInsight: model.trendDirectionDetail,
            projectedWeeklySessions: model.projectedWeeklySessions,
            weeklyProjectionText: model.weeklyProjectionText,
            localIntensityRecommendation: model.localIntensityRecommendation,
            oldestPendingSyncAge: model.oldestPendingSyncAgeLabel,
            remoteRefreshCooldown: model.remoteRefreshCooldownRemaining,
            isRefreshingBackend: model.isRefreshingBackend,
            onClearHistory: model.clearHistory,
            onClearSyncQueue: model.clearSyncQueue,
            onRefreshBackend: model.refreshRemoteInsightsButtonTapped,
            onSyncNow: model.syncNowButtonTapped,
            onApplyCoachPreset: model.applyCoachRecommendedPreset,
            onApplyLocalIntensityRecommendation: model.applyLocalIntensityRecommendation,
            onStart: model.startChallenge
        )
    }
}
