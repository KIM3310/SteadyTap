# Decision Log (CoT-Style Execution Summary)

This log captures concise, auditable reasoning outcomes rather than hidden internal thought.

## Decision 1: Stay offline-first, but keep local continuity

Reason:
- Challenge review environments can be network-constrained.

Choice:
- Keep all calibration and scoring logic on-device.
- Persist only local preferences and recent run summaries via `UserDefaults`.

Tradeoff:
- No cross-device sync, but reliable replay and progress continuity.

## Decision 2: Use two-signal calibration (tap + drag)

Reason:
- Tap-only data misses swipe instability behavior.

Choice:
- Collect both point-tap and lane-drag signals before adaptation.

Tradeoff:
- Slightly longer onboarding, stronger adaptation quality.

## Decision 3: Fair baseline/adaptive comparison

Reason:
- Different random targets between rounds make comparison noisy.

Choice:
- Reuse one generated sequence for both baseline and adaptive challenges.

Tradeoff:
- Less variety, better measurement validity.

## Decision 4: Expose adaptation and scoring transparently

Reason:
- Judges need to see what changed and why.

Choice:
- Show profile parameters, stability band, scoring mode, and before/after deltas.

Tradeoff:
- More metrics on screen, better explainability.

## Decision 5: Add tunable scoring presets

Reason:
- Demo emphasis can vary (accuracy-first vs speed-first).

Choice:
- Provide Mistake-first, Balanced, and Speed-first presets in intro.

Tradeoff:
- More UI controls, clearer evaluation intent.

## Decision 6: Filter touch input with adaptive thresholds

Reason:
- Raw tap gestures can misfire under tremor-induced movement.

Choice:
- Use `swipeThreshold` for tap-drift rejection and long-press max distance.

Tradeoff:
- Slightly stricter input acceptance, fewer accidental activations.

## Decision 7: Raise visual craft quality

Reason:
- A polished interface improves perceived product maturity in short demos.

Choice:
- Introduce animated aurora background, frosted cards, refined typography, and staged reveal motion.

Tradeoff:
- Higher UI complexity, stronger first impression.

## Decision 8: Keep App Playground manifest aligned with Apple template style

Reason:
- Submission compatibility is more important than custom build plumbing.

Choice:
- Continue using `AppleProductTypes` + `.iOSApplication` manifest style.

Tradeoff:
- Generic SwiftPM CLI cannot fully validate this manifest mode.

## Decision 9: Add calibration review gate before challenge

Reason:
- Users and judges need confidence in generated adaptation parameters.

Choice:
- Insert a dedicated review screen showing stability/confidence and allow recalibration.

Tradeoff:
- One extra interaction step, but stronger trust and explainability.

## Decision 10: Add flow-level navigation safety

Reason:
- Mid-flow abandonment without explicit control feels brittle.

Choice:
- Add a shared flow header with stage progress + exit confirmation.

Tradeoff:
- Slightly denser chrome, better control and clarity.

## Decision 11: Introduce local-first backend architecture

Reason:
- Real users need continuity with or without network availability.

Choice:
- Add backend mode (`Local AI` / `Cloud API`) and keep mock intelligence as deterministic fallback.
- Keep calibration/training core fully local.

Tradeoff:
- More state complexity, better reliability and deployment flexibility.

## Decision 12: Add retryable sync queue for uploads

Reason:
- Network upload failures should not block user flow or lose outcomes.

Choice:
- Convert completed sessions to `SessionUploadPayload` and enqueue as `SyncJob`.
- Support auto-sync, manual retry, and queue reset.

Tradeoff:
- Additional persistence/ops UI complexity, significantly stronger real-world resilience.

## Decision 13: Surface backend observability in UI

Reason:
- Production-grade apps should expose service health and sync state to users.

Choice:
- Add dashboard cards for sync health, pending jobs, remote coach plan, and benchmark snapshot.

Tradeoff:
- Denser home dashboard, much better operational transparency.

## Decision 14: Store cloud token in Keychain

Reason:
- Production apps should not persist API bearer tokens in plain app preferences.

Choice:
- Keep token in Keychain and persist only non-sensitive backend settings in preferences.

Tradeoff:
- Additional platform-specific code, improved security posture for real deployment.

## Decision 15: Promote actionability with momentum + one-tap recommendation apply

Reason:
- Users improve faster when analytics and recommended action are immediately executable.

Choice:
- Add momentum trend sparkline, weekly cadence, streak metrics, and one-tap preset apply from coach plan.

Tradeoff:
- Slightly denser dashboard, stronger conversion from insight to action.

## Decision 16: Add intensity planning and weekly-goal execution layer

Reason:
- Users need clear progression control, not only analytics and score comparisons.

Choice:
- Introduce challenge intensity modes (`Supportive`, `Standard`, `Advanced`) that tune adaptive profile strictness and round count.
- Add weekly goal target with live progress/remaining-session visibility.
- Upgrade coach apply action from preset-only to full setup apply (preset + intensity + weekly target).

Tradeoff:
- More state and UI density, substantially better real-world adherence and next-step clarity.

## Decision 17: Harden runtime stability for evolving app versions

Reason:
- Service quality drops if model upgrades break persisted sync queues or if backend settings trigger excessive network calls.

Choice:
- Add backward-compatible decoding defaults for newly added upload payload fields.
- Debounce remote insight refresh when backend/user settings are edited.
- Persist intensity/weekly-goal fields in backend SQLite for better operational traceability.

Tradeoff:
- Slightly more implementation complexity, materially better upgrade safety and runtime responsiveness.

## Decision 18: Add predictive training intelligence on top of analytics

Reason:
- High-quality coaching UX requires immediate "what to do next" guidance, not only historical metrics.

Choice:
- Add local readiness score, short-term trend direction, weekly pace projection, and a local next-intensity recommendation.
- Surface these insights in both home and results views so users can act on them without leaving the flow.
- Keep coach recommendation and local recommendation side-by-side for transparency.

Tradeoff:
- More dashboard density and computed state, significantly better decision support and adherence.
