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
            actionItems: []
        )

        let coach = IntroQuickStartContent(
            coachPlan: plan,
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            localIntensityRecommendation: .advanced,
            readinessBand: "Prime",
            weeklyGoalStatusText: "1 session left to hit this week's goal.",
            latestResultText: "Last run today"
        )
        precondition(coach.recommendationLabel == "Apply Coach Setup")
        precondition(coach.steps.count == 3)
        precondition(coach.recommendationStatus.contains("Apply the coach setup first"))

        let local = IntroQuickStartContent(
            coachPlan: nil,
            scoringPreset: .balanced,
            challengeIntensity: .standard,
            weeklyGoalTarget: 4,
            localIntensityRecommendation: .standard,
            readinessBand: "Building",
            weeklyGoalStatusText: "Weekly goal achieved. Keep momentum and protect consistency.",
            latestResultText: "No previous local runs yet."
        )
        precondition(local.recommendationDisabled)
        precondition(local.recommendationDetail.contains("Weekly goal achieved"))
        precondition(local.recommendationStatus.contains("already active"))
        print("SteadyTap quick-start regression OK")
    }
}
