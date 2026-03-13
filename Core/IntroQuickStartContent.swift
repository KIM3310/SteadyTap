import Foundation

struct IntroQuickStartContent {
    let title: String
    let summary: String
    let recommendationLabel: String
    let recommendationDetail: String
    let recommendationDisabled: Bool
    let focusItems: [String]

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
            recommendationDisabled = coachSetupActive
            focusItems = [
                "Readiness · \(readinessBand)",
                "Coach focus · \(coachPlan.focusArea)",
                "Latest proof · \(latestResultText)"
            ]
        } else {
            title = "Today's first helpful run"
            summary = "Start with the local \(localIntensityRecommendation.title.lowercased()) intensity suggestion, then calibrate once so your first benchmark feels trustworthy."
            recommendationLabel = localIntensityRecommendation == challengeIntensity ? "Local Suggestion Active" : "Apply Local Suggestion"
            recommendationDetail = "\(localIntensityRecommendation.title) intensity · \(weeklyGoalStatusText)"
            recommendationDisabled = localIntensityRecommendation == challengeIntensity
            focusItems = [
                "Readiness · \(readinessBand)",
                "Weekly goal · \(weeklyGoalStatusText)",
                "Latest proof · \(latestResultText)"
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
