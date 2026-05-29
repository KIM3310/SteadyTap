# Review Guide - SteadyTap

Updated: 2026-05-30

Use this page as the short path through the repository. It keeps the review grounded in the code, docs, commands, and boundaries that are already present.

## Summary

| Field | Notes |
|---|---|
| Lane | B2C/B2B2C accessibility coaching |
| Core idea | Offline-first iOS coaching with optional sync and caregiver/team reporting. |
| Primary reader | Accessibility-focused users, care teams, educators, and mobile product teams. |
| Stack | Python, Swift, Terraform, Docker |

## Open First

1. Start with the README fast path and architecture section.
2. Open `docs/monetization-playbook.md` only when reviewing the product or service angle.
3. Check the commands below before making claims about quality.
4. Skim the CI workflows and fixture data before deeper implementation review.
5. Read the boundaries section before presenting the project externally.

## Checks

| Purpose | Command |
|---|---|
| Full local gate | `make verify` |
| Build check | `swift build` |

## CI

- .github/workflows/app-ci.yml
- .github/workflows/architecture-blueprint.yml
- .github/workflows/backend-ci.yml
- .github/workflows/ci.yml
- .github/workflows/dependency-review.yml
- .github/workflows/pages-auto-deploy.yml
- .github/workflows/repository-health.yml
- .github/workflows/repository-surface.yml
- .github/workflows/secret-scan.yml

## Evidence

- pytest/ruff-style local verification path
- Swift Package/Xcode review path
- infrastructure-as-code review surface
- containerized delivery path
- Swift build passes
- Backend checks pass
- Local/offline mode is clear

## Commercial Notes

| Possible offer | Working price assumption |
|---|---|
| Freemium iOS app | Free + $4-$9/month individual |
| Paid coaching plan templates | $99-$499/month small cohort |
| Caregiver or education cohort dashboard pilot | $3k-$10k accessibility program pilot |

## Boundaries

- Sensitive routine data needs consent
- Avoid medical/therapeutic claims
- Sync must be opt-in

## Useful Metrics

- Weekly active routines
- Routine completion
- Opt-in sync conversion
