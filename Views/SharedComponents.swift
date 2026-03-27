import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0.04, green: 0.06, blue: 0.12)
    static let deepBlue = Color(red: 0.07, green: 0.13, blue: 0.24)
    static let ocean = Color(red: 0.1, green: 0.23, blue: 0.33)
    static let mint = Color(red: 0.2, green: 0.82, blue: 0.75)
    static let amber = Color(red: 0.98, green: 0.74, blue: 0.3)
    static let coral = Color(red: 0.94, green: 0.52, blue: 0.45)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.82)
    static let textTertiary = Color.white.opacity(0.68)
}

struct AtmosphereBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.ink, AppTheme.deepBlue, AppTheme.ocean],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppTheme.mint.opacity(0.26))
                .frame(width: 380, height: 380)
                .blur(radius: 32)
                .offset(
                    x: animate ? -180 : -90,
                    y: animate ? -300 : -210
                )

            Circle()
                .fill(AppTheme.amber.opacity(0.23))
                .frame(width: 320, height: 320)
                .blur(radius: 36)
                .offset(
                    x: animate ? 150 : 70,
                    y: animate ? 250 : 170
                )

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(AppTheme.coral.opacity(0.16))
                .frame(width: 360, height: 260)
                .blur(radius: 38)
                .rotationEffect(.degrees(animate ? 22 : -14))
                .offset(
                    x: animate ? 120 : 40,
                    y: animate ? -160 : -90
                )

            Canvas { context, size in
                let spacing: CGFloat = 42
                var path = Path()

                stride(from: CGFloat.zero, through: size.width, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                stride(from: CGFloat.zero, through: size.height, by: spacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            guard !reduceMotion else {
                return
            }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct ScreenContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
    }
}

struct FlowHeader: View {
    let phase: AppPhase
    let onExitTapped: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.flowTitle)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        if let stepLabel = phase.flowStepLabel {
                            Text(stepLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }

                    Spacer()

                    Button("Exit", action: onExitTapped)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityHint("Return to home and reset current run")
                }

                ProgressView(value: phase.flowProgress)
                    .tint(AppTheme.mint)
                    .accessibilityLabel("Flow progress")
                    .accessibilityValue("\(Int(phase.flowProgress * 100)) percent")
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.amber, Color(red: 1.0, green: 0.84, blue: 0.56)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.45), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(
                color: AppTheme.amber.opacity(configuration.isPressed ? 0.1 : 0.28),
                radius: configuration.isPressed ? 6 : 16,
                x: 0,
                y: configuration.isPressed ? 3 : 10
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

struct ComparisonBar: View {
    let title: String
    let baseline: Double
    let adaptive: Double
    let baselineColor: Color
    let adaptiveColor: Color
    let formatter: (Double) -> String

    private var maxValue: Double {
        max(1, baseline, adaptive)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("Base \(formatter(baseline))  |  Adapt \(formatter(adaptive))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            VStack(spacing: 7) {
                progressTrack(
                    value: baseline,
                    color: baselineColor
                )
                progressTrack(
                    value: adaptive,
                    color: adaptiveColor
                )
            }
        }
    }

    private func progressTrack(value: Double, color: Color) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.08))
                .frame(height: 10)

            Capsule()
                .fill(color)
                .frame(
                    width: max(16, CGFloat(value / maxValue) * 250),
                    height: 10
                )
                .animation(.easeInOut(duration: 0.4), value: value)
        }
    }
}

struct StatusChip: View {
    let title: String
    let tone: Tone

    enum Tone {
        case good
        case neutral
        case caution
        case critical

        var color: Color {
            switch self {
            case .good:
                return AppTheme.mint
            case .neutral:
                return AppTheme.textTertiary
            case .caution:
                return AppTheme.amber
            case .critical:
                return AppTheme.coral
            }
        }
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black.opacity(0.72))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tone.color.opacity(0.95))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.45), lineWidth: 1)
                    )
            )
    }
}

struct SparklineView: View {
    let values: [Double]
    let lineColor: Color
    let fillColor: Color

    private var normalizedPoints: [CGFloat] {
        guard !values.isEmpty else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(0.0001, maxValue - minValue)
        return values.map { CGFloat(($0 - minValue) / range) }
    }

    var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints
            let width = geometry.size.width
            let height = geometry.size.height

            if points.count > 1 {
                let stepX = width / CGFloat(points.count - 1)

                let linePath = Path { path in
                    for (index, normalizedY) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (normalizedY * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                let areaPath = Path { path in
                    path.addPath(linePath)
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }

                areaPath
                    .fill(
                        LinearGradient(
                            colors: [fillColor.opacity(0.42), fillColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(lineColor)
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat(points.count - 1) * stepX,
                        y: height - (points.last! * height)
                    )
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.white.opacity(0.12))
            }
        }
    }
}
