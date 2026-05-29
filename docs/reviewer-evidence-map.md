# Reviewer Evidence Map - SteadyTap

Updated: 2026-05-29

This document is the short path for a recruiter, hiring manager, technical reviewer, or buyer who wants to understand what this repository proves without wandering through every file.

## One-Line Proof

**B2C/B2B2C accessibility coaching.** Offline-first iOS coaching with optional sync and caregiver/team reporting.

## Audience and Commercial Angle

| Lens | Answer |
|---|---|
| Primary reviewer | Accessibility-focused users, care teams, educators, and mobile product teams. |
| Hiring signal | Can the project be explained, verified, bounded, and extended like a real product surface? |
| Buyer signal | Is there a narrow operational pain, a runnable proof path, and a risk-aware pilot shape? |
| Stack signal | Python, Swift, Terraform, Docker |

## Seven-Minute Review Route

1. Read the README `Product and Review Surface` and `Reviewer Fast Path` sections.
2. Open `docs/monetization-playbook.md` to understand the buyer, offer ladder, and GTM hypothesis.
3. Run or inspect the strongest local quality gate below.
4. Inspect CI workflow definitions and test fixtures before deeper implementation review.
5. Check the risk boundaries so claims stay credible and not overextended.

## Verification Commands

| Purpose | Command |
|---|---|
| Full local gate | `make verify` |
| Build check | `swift build` |

## CI and Automation Surface

- .github/workflows/app-ci.yml
- .github/workflows/architecture-blueprint.yml
- .github/workflows/backend-ci.yml
- .github/workflows/ci.yml
- .github/workflows/dependency-review.yml
- .github/workflows/pages-auto-deploy.yml
- .github/workflows/repository-health.yml
- .github/workflows/repository-surface.yml
- .github/workflows/secret-scan.yml

## Evidence Inventory

- pytest/ruff-style local verification path
- Swift Package/Xcode review path
- infrastructure-as-code review surface
- containerized delivery path
- Swift build passes
- Backend checks pass
- Local/offline mode is clear

## Commercialization Snapshot

| Offer | Pricing hypothesis |
|---|---|
| Freemium iOS app | Free + $4-$9/month individual |
| Paid coaching plan templates | $99-$499/month small cohort |
| Caregiver or education cohort dashboard pilot | $3k-$10k accessibility program pilot |

## Risk Boundaries

- Sensitive routine data needs consent
- Avoid medical/therapeutic claims
- Sync must be opt-in

## Metrics That Matter

- Weekly active routines
- Routine completion
- Opt-in sync conversion

## Review Verdict

This repository should be evaluated as part of the broader KIM3310 portfolio: it is strongest when the reviewer sees the link between a concrete implementation, a documented verification path, and a monetizable or employable operating story.
