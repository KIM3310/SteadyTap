# SteadyTap SpecKit

## 1) Product Mission

Create a 3-minute App Playground that demonstrates how interface controls can adapt to a user's touch stability and reduce accidental interactions.

## 2) Problem Statement

Users with hand tremor or fine motor limitations often face:
- frequent mistaps
- accidental swipes
- unreliable small-target interactions

Most app UIs are tuned for average motor behavior and do not self-adjust.

## 3) Target Users

- Primary: students and adults with mild-to-moderate hand tremor
- Secondary: temporary motor impairment users (fatigue, stress, injury)
- Tertiary: educators and judges evaluating inclusive design quality

## 4) Product Scope

### In scope

- local touch calibration (tap + drag)
- profile generation from observed motor signals
- baseline vs adaptive comparison
- accessibility-conscious visual and interaction design
- local-first persistence and offline resilience
- optional cloud sync for session summaries
- remote coach-plan and benchmark retrieval

### Out of scope

- medical diagnosis claims
- raw sensor streaming beyond touch interactions

## 5) Functional Requirements

1. App starts with a clear one-screen value proposition.
2. Tap calibration captures at least 10 samples.
3. Drag calibration captures at least 4 successful runs.
4. Calibration outputs numerical metrics:
- tap mean error
- tap standard deviation
- drag mean deviation
- average reaction time
5. Adaptive profile computes:
- button scale
- spacing
- hold duration
- swipe threshold
6. Baseline and adaptive practice use identical target sequences.
7. Result screen reports deltas (misses, time, score).
8. App supports complete offline execution.
9. User can switch scoring preset and challenge intensity before calibration starts.
10. Practice input filtering applies adaptive swipe-threshold tolerance to reduce accidental drag taps.
11. App stores local run history (recent sessions and best delta) and supports history reset.
12. User can toggle haptic feedback before starting a run.
13. App shows a calibration review step with confidence feedback before baseline challenge starts.
14. Result summary can be shared via system share sheet.
15. App provides backend mode switching (local-only / cloud-preferred).
16. App stores upload jobs in a sync queue and supports manual retry.
17. Home dashboard shows remote coach-plan and benchmark data when available.
18. Home dashboard visualizes momentum trend (sparkline), weekly sessions, and streak.
19. Coach recommendation can be applied in one tap as a full setup (preset + intensity + weekly target).
20. Home and results screens expose weekly goal progress and remaining-session guidance.
21. Service computes local readiness/trend and suggests next intensity without requiring cloud.
22. Home dashboard shows projected weekly session pace and goal-closure guidance.

## 6) Non-Functional Requirements

- Runtime stability without network dependencies
- Clear text hierarchy for fast judge comprehension
- Dynamic Type friendly typography
- VoiceOver-readable control labels
- Predictable flow with no dead ends
- Distinct visual system with animated background and staged transitions
- Secure local storage for API bearer token (Keychain)

## 7) Evaluation Mapping (Challenge-Oriented)

- Innovation: adaptive interaction profile from live touch behavior
- Creativity: immediate before/after interaction experiment
- Social impact: accessibility for motor-control barriers
- Inclusivity: no-login, no-cloud, low cognitive overhead
- Technical execution: modular engine + measurable outputs

## 8) Data Model Summary

- `TapSample`: target point, actual point, response elapsed time
- `DragSample`: drag points, lane reference, elapsed time
- `CalibrationResult`: aggregated touch stability signals
- `InteractionProfile`: generated UI adaptation settings
- `PracticeMetrics`: errors/time/score for comparison
- `SessionSummary`: local record of baseline/adaptive outcomes per run
- `AppPreferences`: local UI/feedback preferences, selected intensity, and weekly goal target
- `SessionUploadPayload`: backend upload DTO for completed sessions
- `SyncJob`: retryable upload job stored locally
- `CoachPlan` / `BenchmarkSnapshot`: remote intelligence models
- `CoachPlan.actionItems`: concrete next actions for execution
- `CoachPlan.recommendedIntensity`: backend-recommended challenge intensity mode

## 9) Interaction Flow

1. Intro
2. Tap calibration
3. Drag calibration
4. Calibration review
5. Baseline challenge
6. Adaptive challenge
7. Results + restart/share
8. Optional sync + remote dashboard refresh

## 10) 3-Minute Demo Script

- 0:00-0:20: explain motor-accessibility problem
- 0:20-1:10: run tap and drag calibration
- 1:10-1:30: review generated profile and confidence
- 1:30-2:00: baseline challenge
- 2:00-2:35: adaptive challenge
- 2:35-3:00: show deltas, insight text, and share summary

## 11) Risks and Mitigations

1. Risk: Adaptive mode may increase completion time due to hold delay.
- Mitigation: scoring weights misses/accidental taps more heavily than raw speed.
2. Risk: inconsistent tap behavior during calibration.
- Mitigation: guided instructions and fixed minimum sample count.
3. Risk: fairness concern between baseline and adaptive tasks.
- Mitigation: identical target sequence across both runs.

## 12) Acceptance Criteria

- App launches and completes full flow without internet.
- Adaptive profile always generated after calibration.
- Results screen always shows baseline/adaptive metrics.
- Restart returns user to intro with fresh rounds.
- Recent local run history persists across relaunches.
- Pending upload jobs persist across relaunches and can be retried.
