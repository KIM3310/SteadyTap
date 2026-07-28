import Foundation

struct IntroQuickStartContent {
    let title: String
    let summary: String
    let recommendationLabel: String
    let recommendationDetail: String
    let recommendationStatus: String
    let recommendationDisabled: Bool
    let calibrationNote: String
    let localDataNote: String

    init(
        coachPlan: CoachPlan?,
        scoringPreset: ScoringPreset,
        challengeIntensity: ChallengeIntensity,
        weeklyGoalTarget: Int,
        localIntensityRecommendation: ChallengeIntensity,
        weeklyGoalStatusText: String
    ) {
        if let coachPlan {
            title = "Start with the coach setup"
            summary = "Apply the recommended touch settings, then calibrate before timed practice."
            let coachSetupActive = coachPlan.recommendedPreset == scoringPreset
                && coachPlan.recommendedIntensity == challengeIntensity
                && coachPlan.targetSessionsPerWeek == weeklyGoalTarget
            recommendationLabel = coachSetupActive ? "Coach setup active" : "Use coach setup"
            recommendationDetail = "\(coachPlan.recommendedPreset.shortTitle) · \(coachPlan.recommendedIntensity.shortTitle) · \(coachPlan.targetSessionsPerWeek)x / week"
            recommendationStatus = coachSetupActive
                ? "Current controls match the coach setup."
                : "Use the coach setup before calibration."
            recommendationDisabled = coachSetupActive
            calibrationNote = "Calibration checks comfort before baseline and adaptive rounds."
            localDataNote = "Calibration and result review remain available without cloud sync."
        } else {
            title = "Start with calibration"
            summary = "Use the \(localIntensityRecommendation.title.lowercased()) intensity suggestion, then calibrate once before timed practice."
            recommendationLabel = localIntensityRecommendation == challengeIntensity ? "Suggested setup active" : "Use suggested setup"
            recommendationDetail = "\(localIntensityRecommendation.title) intensity · \(weeklyGoalStatusText)"
            recommendationStatus = localIntensityRecommendation == challengeIntensity
                ? "Current controls match the suggestion."
                : "Use the suggested intensity before calibration."
            recommendationDisabled = localIntensityRecommendation == challengeIntensity
            calibrationNote = "Calibration checks target size and movement before timed practice."
            localDataNote = "Results and progress stay on this device."
        }
    }

    var steps: [String] {
        if recommendationDisabled {
            return [
                "Keep the current setup and run calibration.",
                "Review target size and movement comfort.",
                "Complete baseline and adaptive rounds, then compare results."
            ]
        }
        return [
            "Use the recommended setup.",
            "Run calibration and review target comfort.",
            "Complete baseline and adaptive rounds, then compare results."
        ]
    }
}
