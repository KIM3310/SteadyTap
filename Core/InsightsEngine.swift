import Foundation

enum InsightsEngine {
    static func performanceSummary(
        baseline: PracticeMetrics,
        adaptive: PracticeMetrics,
        scoringPreset: ScoringPreset
    ) -> String {
        let scoreDelta = adaptive.score(using: scoringPreset) - baseline.score(using: scoringPreset)
        let missDelta = baseline.misses - adaptive.misses
        let timeDelta = baseline.completionTime - adaptive.completionTime

        if scoreDelta >= 12 {
            return "Strong improvement. Adaptive mode is clearly reducing interaction cost for this profile."
        }
        if scoreDelta >= 4 {
            return "Meaningful improvement. Adaptive settings are helping, especially on control precision."
        }
        if missDelta > 0 && timeDelta < 0 {
            return "Accuracy improved but speed dropped. This tradeoff is typical when hold safeguards are added."
        }
        if missDelta <= 0 && timeDelta >= 0 {
            return "Speed improved but accuracy gain is limited. Consider using the Mistake-first scoring mode."
        }
        return "Current profile is close to baseline. Another calibration run can produce a tighter adaptation."
    }

    static func profileRecommendation(
        calibration: CalibrationResult,
        profile: InteractionProfile
    ) -> String {
        let base = calibration.stabilityBand.guidance
        let hold = String(format: "%.2f", profile.holdDuration)
        let scale = String(format: "%.2f", profile.buttonScale)
        return "\(base) \(calibration.confidenceBand.hint) Current adaptive settings: \(scale)x target size and \(hold)s confirmation hold."
    }
}
