# SteadyTap verification

Reviewed 2026-09-16. Each check proves only the behavior it exercises. The static website is an explainer, not a browser implementation of the native app.

## Shared Swift core

```sh
./scripts/verify_cli.sh
```

This command requires the Swift toolchain on macOS. It compiles the actual shared Core files and runs the CLI regression checks without the asset compiler. It does not build the SwiftUI app or exercise native gestures. [scripts/verify_cli.sh](../scripts/verify_cli.sh) lists the compiled sources and assertions.

## Release metadata and policy

```sh
make verify-app-store
```

This command requires Python 3 and macOS `plutil`. It validates release-policy declarations, submission metadata, the app icon catalog, and the privacy manifest. It also lints all three plist files. See [scripts/validate_app_store_readiness.py](../scripts/validate_app_store_readiness.py). This is not an iOS build or Apple approval.

## Separate backend sandbox

```sh
make verify-backend
```

Python 3.11+ is required to create the project's backend virtual environment. If `python3` is older, select a suitable interpreter explicitly.

```sh
make BOOTSTRAP_PYTHON=/path/to/python3.11 verify-backend
```

The Makefile creates `backend/.venv`, checks dependencies, compiles Python files, runs Ruff, and runs the synthetic backend tests with warnings treated as errors. The audited baseline passed all 12 tests. See [backend/tests/test_api.py](../backend/tests/test_api.py) and [backend/tests/test_cors.py](../backend/tests/test_cors.py). FastAPI is a separate debug sandbox, not the release app's required runtime.

## Static content and architecture checks

```sh
python3 -m unittest discover -s scripts/tests -p "test_*.py"
python3 scripts/validate_repository_surface.py
python3 scripts/validate_architecture_blueprint.py
```

These checks cover public copy, local HTML links and fragments, cited repository files, repository metadata, and the architecture manifest's structure. They do not replace browser layout checks or native app tests.

## Native builds require full Xcode

```sh
swift test
make generate-xcode-project
```

Use a Mac with full Xcode selected. The generated Xcode project is the native app build entry point. `make generate-xcode-project` uses the repository's XcodeGen installer. `make verify` starts with `swift build`, so it is not a Command Line Tools-only shortcut.

The 2026-09-16 local audit had only Apple Command Line Tools. `swift test` stopped because `actool` requires full Xcode. No local XCTest, unsigned iOS app build, simulator launch, or native gesture run is claimed for that environment.

[UITests/CalibrationFlowTests.swift](../UITests/CalibrationFlowTests.swift) defines the real tap and drag flow. [.github/workflows/app-store-readiness.yml](../.github/workflows/app-store-readiness.yml) defines the unsigned device build, simulator launch, and gesture checks. Inspect the run's exact revision and artifacts before using it as native evidence.

## Revision-specific evidence

- The 2026-09-16 local audit at `cd0bf9f7601da0b81baeb53086e13ff99d4ac022` passed the shared-core CLI, metadata checks, repository validators, and 12 backend tests. The [CI run for that revision](https://github.com/KIM3310/SteadyTap/actions/runs/34193067807) also reports success. These results do not imply native checks at a later revision.
- The [recorded app-store-readiness run](https://github.com/KIM3310/SteadyTap/actions/runs/34190470210) reports success for `ac5f099b2b553f1926a2fb6ffca05f8eee10b611`. This is an earlier revision. The local audit did not replay its native artifacts.
- The [Pages run at the audited baseline](https://github.com/KIM3310/SteadyTap/actions/runs/34193067771) is green, but its upload was skipped because required secrets were absent. That run is not evidence of a deployment or the current website revision.

Rerun the commands for your checkout. A successful validation job alone does not prove publication. Compare the deployed revision and page bytes using the [Pages publication procedure](deployment/CLOUDFLARE_PAGES.md).

## Limits

No physical iPhone/iPad test or App Store publication is claimed. Signed distribution requires an Apple Developer team and provisioning. Calibration confidence is a coverage and consistency heuristic, not a clinical measure or a validated health outcome. App Store Release remains on-device.

The checks do not establish security certification, regulatory approval, production availability, or a customer outcome. Commit history records changes but does not establish manual or AI contribution percentages.

[Back to the project](../README.md)
