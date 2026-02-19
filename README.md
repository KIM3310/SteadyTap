# SteadyTap (Swift Student Challenge App Playground)

SteadyTap is an accessibility-first App Playground that adapts touch interaction settings from a short calibration.

Flow:
1. Tap calibration
2. Drag calibration
3. Calibration review
4. Baseline challenge
5. Adaptive challenge
6. Before/after report

Quality upgrades included:
- Input filtering that uses adaptive `swipeThreshold` to reject unstable tap drags
- Three scoring presets selectable before each run
- Local session history with best-improvement tracking
- Haptic feedback toggle and local-history reset controls
- Coach insight text on the results screen
- Animated aurora background, frosted cards, and staged screen reveal animations
- Flow header with step progress and safe exit confirmation
- Calibration confidence scoring + review screen before challenge start
- Shareable result summary from results screen
- Cloud-ready backend mode with sync queue, health state, and retry controls
- Remote coach plan + cohort benchmark cards on the home dashboard
- Momentum dashboard with trend sparkline, weekly cadence, and streak tracking
- Challenge intensity modes (Supportive/Standard/Advanced) with adaptive profile tuning
- Weekly goal planner with live progress tracking
- One-tap apply of full coach setup (preset + intensity + weekly target)
- Backward-compatible sync queue decoding across model upgrades
- Debounced cloud insight refresh while editing backend settings
- Predictive intelligence layer: readiness score, trend direction, and local next-intensity recommendation
- Weekly pace projection with actionable goal-closure guidance

Scoring presets:
- Mistake-first (default): stronger penalty on misses/accidental touches
- Balanced: moderate penalties across speed and mistakes
- Speed-first: higher time pressure with lighter mistake penalties

## Why this project is challenge-friendly

- Fully offline and self-contained
- Clear 3-minute demo narrative
- Personal and social impact angle (motor accessibility)
- Measurable before/after output for judges

## Open in Xcode

1. Open `SteadyTap.swiftpm` in Xcode 26+ (or Swift Playgrounds with App Playground support).
2. Update `teamIdentifier` in `Package.swift` if code signing is needed.
3. Run on iPad or iPhone simulator.

## Cloud backend integration

The app now supports two backend modes from home settings:
- `Local AI`: uses local/mock backend logic only
- `Cloud API`: uses HTTP API and falls back to local when URL is missing

When a session ends, the app enqueues an upload job and syncs automatically (if enabled).
You can also set optional `Bearer Token` for secured cloud APIs (stored in Keychain).

## Companion backend service

A production-oriented FastAPI starter backend is included at:
- `/Users/kim/SteadyTap-backend`

See `/Users/kim/SteadyTap-backend/README.md` for run instructions.

## Submission checklist

- [ ] Confirm app works without internet
- [ ] Keep total size under challenge limits
- [ ] Keep in-app text in English
- [ ] Zip the `.swiftpm` package for submission

## Main files

- `Package.swift`: App Playground product setup
- `Core/BackendClient.swift`: remote/mock backend client layer
- `Core/PersistenceStore.swift`: local persistence (history, preferences, sync queue)
- `Core/AppViewModel.swift`: app orchestration, sync queue, remote insight state
- `Core/CalibrationEngine.swift`: touch metric analysis and adaptive profile generation
- `Views/CalibrationFlowView.swift`: calibration UI
- `Views/IntroView.swift`: production-style home dashboard and backend ops panel
- `Views/PracticeView.swift`: baseline/adaptive challenge
- `Views/ResultsView.swift`: comparison report
- `Views/CalibrationReviewView.swift`: calibration quality review + continue/recalibrate
- `SPECKIT.md`: full product specification
- `DECISION_LOG.md`: structured implementation reasoning log
