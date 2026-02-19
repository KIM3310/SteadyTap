import SwiftUI

struct CalibrationReviewView: View {
    let calibration: CalibrationResult
    let profile: InteractionProfile
    let onContinue: () -> Void
    let onRecalibrate: () -> Void

    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Calibration Complete")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .staged(index: 0, appear: appear)

                Text("Review your generated profile before starting the baseline challenge.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)
                    .staged(index: 1, appear: appear)

                GlassCard {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            MetricTile(title: "Stability", value: calibration.stabilityBand.rawValue)
                            MetricTile(title: "Confidence", value: calibration.confidenceBand.rawValue)
                        }

                        HStack(spacing: 10) {
                            MetricTile(title: "Tap Samples", value: "\(calibration.tapSampleCount)")
                            MetricTile(title: "Drag Samples", value: "\(calibration.dragSampleCount)")
                        }
                    }
                }
                .staged(index: 2, appear: appear)

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Adaptive Settings")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        profileLine("Button scale", String(format: "%.2fx", profile.buttonScale))
                        profileLine("Grid spacing", "\(Int(profile.gridSpacing)) pt")
                        profileLine("Hold duration", String(format: "%.2fs", profile.holdDuration))
                        profileLine("Swipe threshold", "\(Int(profile.swipeThreshold)) pt")

                        Text(calibration.confidenceBand.hint)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .staged(index: 3, appear: appear)

                HStack(spacing: 10) {
                    Button("Recalibrate", action: onRecalibrate)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.coral.opacity(0.8))

                    Button("Continue", action: onContinue)
                        .buttonStyle(PrimaryButtonStyle())
                }
                .staged(index: 4, appear: appear)
            }
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .onAppear {
            appear = true
        }
    }

    private func profileLine(_ label: String, _ value: String) -> some View {
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
}

private extension View {
    func staged(index: Int, appear: Bool) -> some View {
        self
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 18)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.85)
                    .delay(Double(index) * 0.05),
                value: appear
            )
    }
}
