import SwiftUI

struct CalibrationFlowView: View {
    let onComplete: ([TapSample], [DragSample]) -> Void

    @State private var step: Step = .tap
    @State private var tapSamples: [TapSample] = []

    enum Step {
        case tap
        case drag
    }

    var body: some View {
        VStack(spacing: 16) {
            switch step {
            case .tap:
                TapCalibrationStage(requiredCount: 10) { samples in
                    tapSamples = samples
                    withAnimation(.easeInOut(duration: 0.35)) {
                        step = .drag
                    }
                }
            case .drag:
                DragCalibrationStage(requiredCount: 4) { dragSamples in
                    onComplete(tapSamples, dragSamples)
                }
            }
        }
    }
}

private struct TapCalibrationStage: View {
    let requiredCount: Int
    let onFinish: ([TapSample]) -> Void

    @State private var samples: [TapSample] = []
    @State private var currentTarget = CGPoint.zero
    @State private var targetStartTime = Date()
    @State private var initialized = false

    var body: some View {
        VStack(spacing: 14) {
            Text("Calibration 1/2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Text("Tap the glowing target")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Touch the target naturally. We use your distance error and reaction time to tune control sizes.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)

            GeometryReader { geometry in
                let canvasSize = geometry.size

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.08))

                    Circle()
                        .fill(Color(red: 0.93, green: 0.95, blue: 0.96))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.mint, lineWidth: 6)
                        )
                        .position(currentTarget)
                        .shadow(color: .white.opacity(0.35), radius: 16)

                    VStack {
                        HStack {
                            Text("\(samples.count)/\(requiredCount)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.28), in: Capsule())
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            registerTap(at: value.location, in: canvasSize)
                        }
                )
                .onAppear {
                    guard !initialized else {
                        return
                    }
                    initialized = true
                    currentTarget = randomTarget(in: canvasSize)
                    targetStartTime = Date()
                }
            }
            .frame(height: 360)

            Text("Tip: stay consistent and use one finger for all taps.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private func registerTap(at location: CGPoint, in size: CGSize) {
        let elapsed = Date().timeIntervalSince(targetStartTime)
        let sample = TapSample(target: currentTarget, actual: location, elapsed: elapsed)
        samples.append(sample)
        HapticsManager.light()

        if samples.count >= requiredCount {
            onFinish(samples)
            return
        }

        currentTarget = randomTarget(in: size)
        targetStartTime = Date()
    }

    private func randomTarget(in size: CGSize) -> CGPoint {
        let margin: CGFloat = 44
        let clampedWidth = max(size.width - (margin * 2), 1)
        let clampedHeight = max(size.height - (margin * 2), 1)

        return CGPoint(
            x: CGFloat.random(in: 0...clampedWidth) + margin,
            y: CGFloat.random(in: 0...clampedHeight) + margin
        )
    }
}

private struct DragCalibrationStage: View {
    let requiredCount: Int
    let onFinish: ([DragSample]) -> Void

    @State private var samples: [DragSample] = []

    var body: some View {
        VStack(spacing: 14) {
            Text("Calibration 2/2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Text("Trace the horizontal lane")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Start near the left marker and drag to the right marker. We estimate swipe steadiness.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)

            DragLaneView(requiredCount: requiredCount, samples: $samples) {
                onFinish(samples)
            }
            .frame(height: 340)

            Text("Successful runs: \(samples.count)/\(requiredCount)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

private struct DragLaneView: View {
    let requiredCount: Int
    @Binding var samples: [DragSample]
    let onDone: () -> Void

    @State private var activePoints: [CGPoint] = []
    @State private var dragStartTime = Date()

    var body: some View {
        GeometryReader { geometry in
            let laneY = geometry.size.height * 0.56
            let startX: CGFloat = 46
            let endX: CGFloat = geometry.size.width - 46

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.08))

                Path { path in
                    path.move(to: CGPoint(x: startX, y: laneY))
                    path.addLine(to: CGPoint(x: endX, y: laneY))
                }
                .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 7, lineCap: .round, dash: [8, 10]))

                Circle()
                    .fill(AppTheme.amber)
                    .frame(width: 18, height: 18)
                    .position(x: startX, y: laneY)

                Circle()
                    .fill(AppTheme.mint)
                    .frame(width: 18, height: 18)
                    .position(x: endX, y: laneY)

                if activePoints.count > 1 {
                    Path { path in
                        path.addLines(activePoints)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .shadow(color: .white.opacity(0.25), radius: 10)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if activePoints.isEmpty {
                            dragStartTime = Date()
                        }
                        activePoints.append(value.location)
                    }
                    .onEnded { value in
                        finalizeDrag(endPoint: value.location, laneY: laneY, width: geometry.size.width)
                    }
            )
        }
    }

    private func finalizeDrag(endPoint: CGPoint, laneY: CGFloat, width: CGFloat) {
        activePoints.append(endPoint)

        let startNearLeft = (activePoints.first?.x ?? 0) < 84
        let endNearRight = endPoint.x > (width - 84)

        if startNearLeft && endNearRight {
            let sample = DragSample(points: activePoints, referenceY: laneY, elapsed: Date().timeIntervalSince(dragStartTime))
            samples.append(sample)
            HapticsManager.success()
        } else {
            HapticsManager.failure()
        }

        activePoints.removeAll(keepingCapacity: true)

        if samples.count >= requiredCount {
            onDone()
        }
    }
}
