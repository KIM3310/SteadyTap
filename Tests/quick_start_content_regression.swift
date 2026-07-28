import Foundation

@main
struct QuickStartContentRegression {
    static func main() {
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
            weeklyGoalStatusText: "1 session left to hit this week's goal."
        )
        precondition(coach.recommendationLabel == "Use coach setup")
        precondition(coach.calibrationNote.contains("Calibration checks comfort"))
        precondition(coach.localDataNote.contains("without cloud sync"))
        precondition(coach.steps.count == 3)
        precondition(coach.recommendationStatus == "Use the coach setup before calibration.")

        let local = IntroQuickStartContent(
            coachPlan: nil,
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            localIntensityRecommendation: .standard,
            weeklyGoalStatusText: "Weekly goal achieved. Keep momentum and protect consistency."
        )
        precondition(local.recommendationDisabled)
        precondition(local.title == "Start with calibration")
        precondition(local.calibrationNote.contains("target size and movement"))
        precondition(local.localDataNote.contains("stay on this device"))
        precondition(local.recommendationDetail.contains("Weekly goal achieved"))
        precondition(local.recommendationStatus == "Current controls match the suggestion.")
        print("SteadyTap quick-start regression OK")
    }
}
