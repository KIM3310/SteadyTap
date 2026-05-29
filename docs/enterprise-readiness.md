# Enterprise Readiness Notes - SteadyTap

Updated: 2026-05-30

This note defines what an enterprise buyer, public-sector reviewer, serious user, or technical evaluator can safely infer from this repository today. It is intentionally conservative: public proof is separated from production claims.

## Scope

| Field | Notes |
|---|---|
| Repository | `SteadyTap` |
| Lane | B2C/B2B2C accessibility coaching |
| Primary reader or buyer | Accessibility-focused users, care teams, educators, and mobile product teams. |
| Core wedge | Offline-first iOS coaching with optional sync and caregiver/team reporting. |
| Stack | Python, Swift, Terraform, Docker |
| Readiness posture | Public demo or product experiment with enterprise-grade privacy and release expectations where applicable. |

## Enterprise Controls

| Control | Current expectation |
|---|---|
| Data boundary | Personal data should stay optional; sync, analytics, and paid features need explicit consent and visible export/delete paths. |
| Identity and access | Keep the first session account-light; add identity only for sync, paid access, team views, or data export. |
| Auditability | Keep decision logs, generated reports, CI results, eval outputs, and operator handoff artifacts reviewable. |
| Observability | Track activation, completion, opt-in sync, export/delete usage, errors, and abuse signals without over-collecting personal data. |
| Release gate | Full local gate: make verify; Build check: swift build |
| Support handoff | Name the owner, escalation path, rollback path, known limits, and review cadence before a paid or production pilot. |

## Verification Surface

| Purpose | Command |
|---|---|
| Full local gate | `make verify` |
| Build check | `swift build` |

## CI Surface

- .github/workflows/app-ci.yml
- .github/workflows/architecture-blueprint.yml
- .github/workflows/backend-ci.yml
- .github/workflows/ci.yml
- .github/workflows/dependency-review.yml
- .github/workflows/pages-auto-deploy.yml
- .github/workflows/repository-health.yml
- .github/workflows/repository-surface.yml
- .github/workflows/secret-scan.yml

## Acceptance Criteria

- make verify can be run or the equivalent CI gate is visible.
- README, review guide, quality notes, revenue model, and this readiness note agree on the same scope.
- Demo, fixture, synthetic, or public-data boundaries are explicit before a buyer sees outputs.
- A reviewer can identify the first useful outcome without reading implementation details.
- Production claims stay behind customer-specific validation, access control, monitoring, and support handoff.

## Integration Path

- Ship a friction-light public demo or app flow that proves first-session value.
- Add consented account, sync, paid pack, or team/cohort layer only after the core loop is useful.
- Measure retention, support issues, opt-outs, and refund/cancel signals before broad monetization.

## Proof Points

- Swift build passes
- Backend checks pass
- Local/offline mode is clear

## Operating Metrics

- Weekly active routines
- Routine completion
- Opt-in sync conversion

## Open Risks

- Sensitive routine data needs consent
- Avoid medical/therapeutic claims
- Sync must be opt-in

## Finish Line

- Keep the public repository honest, runnable, and easy to review.
- Keep sensitive data, secrets, private tenant details, and unsupported claims out of public artifacts.
- Treat this repository as a proof surface until an approved pilot defines users, data, access, monitoring, support, and success metrics.
