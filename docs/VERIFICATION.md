# SteadyTap — implementation and verification

Reviewed 2026-09-07. The repository and linked tests define the evidence; a preview alone does not establish production readiness.

### Tests compile the app source

XCTest source links and the CLI point to the same Core files used by the app. SwiftUI-only view extensions live separately, so the core can be checked without the asset compiler.

### Reject unusable samples

Non-finite coordinates/reaction times, negative elapsed times and empty drag traces cannot inflate sample coverage or poison the generated profile.

### Make release behavior explicit

The distribution policy disables cloud features in release builds. Native CI exercises real gestures without injecting calibration results.

## Reproduce

```sh
./scripts/verify_cli.sh
make verify-app-store
make verify-backend
# On a Mac with Xcode:
swift test
make generate-xcode-project
```

The actual shared Swift core passes the local CLI regression suite; release metadata/privacy checks and 12 backend tests pass. Native iOS release compilation and simulator gesture tests run in the linked GitHub Actions workflow; inspect its result and attached evidence for the exact revision.

## Boundaries

No physical iPhone/iPad test or App Store publication is claimed. Calibration confidence is a coverage/consistency heuristic, not a clinical measure or validated health outcome. App Store Release remains on-device; the FastAPI backend is a separate debug sandbox.

## Attribution

This page describes capabilities visible in the repository. It does not independently establish which lines were written manually, with AI assistance, or by collaborators. The commit history and pull-request diffs preserve the implementation trail; individual/team contribution percentages have not been inferred.

[Back to the project](../README.md)
