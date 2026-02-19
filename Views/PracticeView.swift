import SwiftUI

enum PracticeMode {
    case baseline
    case adaptive

    var title: String {
        switch self {
        case .baseline:
            return "Baseline Challenge"
        case .adaptive:
            return "Adaptive Challenge"
        }
    }

    var subtitle: String {
        switch self {
        case .baseline:
            return "Default button sizes and default gesture behavior"
        case .adaptive:
            return "Controls tuned from your calibration profile"
        }
    }
}

struct PracticeView: View {
    let mode: PracticeMode
    let intensity: ChallengeIntensity
    let profile: InteractionProfile
    let rounds: [Int]
    let onComplete: (PracticeMetrics) -> Void

    @State private var roundIndex = 0
    @State private var misses = 0
    @State private var accidentalTouches = 0
    @State private var startTime = Date()
    @State private var isInputLocked = false

    private var normalizedProfile: InteractionProfile {
        switch mode {
        case .baseline:
            return .baseline
        case .adaptive:
            return profile
        }
    }

    private var currentTarget: Int {
        rounds[safe: roundIndex] ?? 1
    }

    private var modeDescriptor: String {
        "\(intensity.title) intensity | \(rounds.count) rounds"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(mode.title)
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text(modeDescriptor)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(spacing: 8) {
                    Text("Target")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(AppTheme.textTertiary)

                    Text("\(currentTarget)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, AppTheme.mint.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(maxWidth: .infinity)
            }

            Text(interactionHint)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            NumberGrid(
                target: currentTarget,
                profile: normalizedProfile,
                onCorrect: advanceRound,
                onMistake: registerMistake,
                onAccidentalInput: registerAccidentalInput
            )
            .allowsHitTesting(!isInputLocked)
            .opacity(isInputLocked ? 0.85 : 1.0)

            GlassCard {
                VStack(spacing: 10) {
                    HStack {
                        Text("Progress")
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text("\(roundIndex + 1)/\(rounds.count)")
                            .foregroundStyle(AppTheme.textPrimary)
                            .fontWeight(.bold)
                    }

                    ProgressView(value: Double(roundIndex + 1), total: Double(max(rounds.count, 1)))
                        .tint(AppTheme.amber)

                    HStack(spacing: 10) {
                        MetricTile(title: "Misses", value: "\(misses)")
                        MetricTile(title: "Accidental", value: "\(accidentalTouches)")
                    }
                }
            }
        }
        .onAppear {
            startTime = Date()
        }
    }

    private var interactionHint: String {
        if normalizedProfile.holdDuration > 0.1 {
            return "Long-press to select (\(String(format: "%.2f", normalizedProfile.holdDuration))s, max drift \(Int(normalizedProfile.swipeThreshold))pt)"
        }
        return "Tap to select (swipe drift over \(Int(normalizedProfile.swipeThreshold))pt is ignored)"
    }

    private func advanceRound() {
        guard !isInputLocked else {
            return
        }
        isInputLocked = true
        HapticsManager.success()

        if roundIndex >= rounds.count - 1 {
            let completion = Date().timeIntervalSince(startTime)
            onComplete(
                PracticeMetrics(
                    misses: misses,
                    rounds: rounds.count,
                    completionTime: completion,
                    accidentalTouches: accidentalTouches
                )
            )
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            roundIndex += 1
        }
        unlockInputSoon()
    }

    private func registerMistake() {
        guard !isInputLocked else {
            return
        }
        misses += 1
        HapticsManager.failure()
        lockBriefly()
    }

    private func registerAccidentalInput() {
        guard !isInputLocked else {
            return
        }
        accidentalTouches += 1
        HapticsManager.light()
        lockBriefly()
    }

    private func lockBriefly() {
        isInputLocked = true
        unlockInputSoon()
    }

    private func unlockInputSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            isInputLocked = false
        }
    }
}

private struct NumberGrid: View {
    let target: Int
    let profile: InteractionProfile
    let onCorrect: () -> Void
    let onMistake: () -> Void
    let onAccidentalInput: () -> Void

    private var numbers: [Int] {
        Array(1...9)
    }

    private var tileSize: CGFloat {
        (50.0 * profile.buttonScale).clamped(to: 48...84)
    }

    var body: some View {
        VStack(spacing: profile.gridSpacing) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: profile.gridSpacing) {
                    ForEach(0..<3, id: \.self) { column in
                        let number = numbers[(row * 3) + column]
                        NumberTile(
                            number: number,
                            size: tileSize,
                            holdDuration: profile.holdDuration,
                            swipeThreshold: profile.swipeThreshold,
                            onSwipeRejected: onAccidentalInput
                        ) {
                            if number == target {
                                onCorrect()
                            } else {
                                onMistake()
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct NumberTile: View {
    let number: Int
    let size: CGFloat
    let holdDuration: TimeInterval
    let swipeThreshold: CGFloat
    let onSwipeRejected: () -> Void
    let onSelect: () -> Void
    @GestureState private var isPressing = false

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        AppTheme.mint.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.26), lineWidth: 1)
            )
            .overlay(
                Text("\(number)")
                    .font(.system(size: max(22, size * 0.4), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            )
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .scaleEffect(isPressing ? 0.95 : 1)
            .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
            .applyIf(holdDuration > 0.1) { view in
                view.onLongPressGesture(
                    minimumDuration: holdDuration,
                    maximumDistance: swipeThreshold,
                    perform: onSelect
                )
            }
            .applyIf(holdDuration <= 0.1) { view in
                view.gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isPressing) { _, state, _ in
                            state = true
                        }
                        .onEnded { value in
                            let movement = value.startLocation.distance(to: value.location)
                            if movement <= swipeThreshold {
                                onSelect()
                            } else {
                                onSwipeRejected()
                            }
                        }
                )
            }
            .accessibilityLabel("Number \(number)")
            .accessibilityHint(accessibilityHint)
    }

    private var accessibilityHint: String {
        if holdDuration > 0.1 {
            return "Long press to select."
        }
        return "Tap to select."
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
