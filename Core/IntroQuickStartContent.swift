import Foundation

struct IntroQuickStartContent {
    let title: String
    let summary: String
    let recommendationLabel: String
    let recommendationDetail: String
    let recommendationStatus: String
    let recommendationDisabled: Bool
    let focusItems: [String]
    let routeChips: [String]

    init(
        coachPlan: CoachPlan?,
        scoringPreset: ScoringPreset,
        challengeIntensity: ChallengeIntensity,
        weeklyGoalTarget: Int,
        localIntensityRecommendation: ChallengeIntensity,
        readinessBand: String,
        weeklyGoalStatusText: String,
        latestResultText: String
    ) {
        if let coachPlan {
            title = "Coach-guided first run"
            summary = "Use the remote coach setup for a \(coachPlan.focusArea.lowercased()) session, then start calibration while your readiness is \(readinessBand.lowercased())."
            let coachSetupActive = coachPlan.recommendedPreset == scoringPreset
                && coachPlan.recommendedIntensity == challengeIntensity
                && coachPlan.targetSessionsPerWeek == weeklyGoalTarget
            recommendationLabel = coachSetupActive ? "Coach Setup Active" : "Apply Coach Setup"
            recommendationDetail = "\(coachPlan.recommendedPreset.shortTitle) · \(coachPlan.recommendedIntensity.shortTitle) · \(coachPlan.targetSessionsPerWeek)x / week"
            recommendationStatus = coachSetupActive
                ? "Coach setup already matches your current controls. Start calibration to confirm the guided setup still feels comfortable."
                : "Apply the coach setup first so your first calibration run matches the remote recommendation."
            recommendationDisabled = coachSetupActive
            focusItems = [
                "Readiness · \(readinessBand)",
                "Coach focus · \(coachPlan.focusArea)",
                "Latest proof · \(latestResultText)"
            ]
            routeChips = [
                coachSetupActive ? "Setup · Coach preset active" : "Setup · Apply coach preset",
                "Run · Calibration before challenge",
                "Review · Local proof before sync"
            ]
        } else {
            title = "Today's first helpful run"
            summary = "Start with the local \(localIntensityRecommendation.title.lowercased()) intensity suggestion, then calibrate once so your first benchmark feels trustworthy."
            recommendationLabel = localIntensityRecommendation == challengeIntensity ? "Local Suggestion Active" : "Apply Local Suggestion"
            recommendationDetail = "\(localIntensityRecommendation.title) intensity · \(weeklyGoalStatusText)"
            recommendationStatus = localIntensityRecommendation == challengeIntensity
                ? "The local suggestion is already active. Keep this setup and start calibration while the recommendation is still fresh."
                : "Apply the local suggestion before calibration so the first benchmark starts from the safest local intensity."
            recommendationDisabled = localIntensityRecommendation == challengeIntensity
            focusItems = [
                "Readiness · \(readinessBand)",
                "Weekly goal · \(weeklyGoalStatusText)",
                "Latest proof · \(latestResultText)"
            ]
            routeChips = [
                localIntensityRecommendation == challengeIntensity ? "Setup · Local suggestion active" : "Setup · Apply local suggestion",
                "Run · Calibration before challenge",
                "Review · Keep cloud optional"
            ]
        }
    }

    var steps: [String] {
        if recommendationDisabled {
            return [
                "Keep the current setup and start calibration.",
                "Review the adaptive profile before baseline practice.",
                "Finish baseline + adaptive runs, then check sync and coaching surfaces."
            ]
        }
        return [
            "Apply the recommended setup first so the first run starts from a grounded preset.",
            "Start calibration and confirm the adaptive profile feels credible.",
            "Finish baseline + adaptive runs, then review the results and sync posture."
        ]
    }
}
