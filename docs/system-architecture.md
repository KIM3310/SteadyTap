# SteadyTap system architecture

SteadyTap is a native SwiftUI touch-practice app for iPhone and iPad. The app measures tap and drag samples, builds an adaptive interaction profile, and compares baseline and adaptive practice. The website explains this flow but does not run the app in a browser.

## Native practice flow

```text
Tap and drag samples
        |
        v
CalibrationEngine.summarize
        |
        v
Adaptive interaction profile
        |
        v
Calibration review
        |
        v
Baseline practice
        |
        v
Adaptive practice
        |
        v
Results and local history
```

[SteadyTapApp.swift](../SteadyTapApp.swift) starts the app. [RootView.swift](../RootView.swift) chooses the SwiftUI screen for the current phase. [Core/AppViewModel.swift](../Core/AppViewModel.swift) owns the calibration, practice, and result transitions.

[Core/CalibrationEngine.swift](../Core/CalibrationEngine.swift) filters unusable samples in `summarize` and derives bounded settings in `generateAdaptiveProfile`. These settings control button scale, grid spacing, hold duration, and swipe threshold. Calibration confidence is a coverage and consistency heuristic, not a clinical measure or a validated health outcome.

## On-device storage

[Core/PersistenceStore.swift](../Core/PersistenceStore.swift) encodes session history and preferences as JSON in UserDefaults. It keeps at most 12 history entries. `clearAll` removes the app's stored history, preferences, and debug cache entries. [Core/AppViewModel.swift](../Core/AppViewModel.swift) calls this storage layer after practice and when the user clears local data.

## Release and debug boundary

[Core/DistributionPolicy.swift](../Core/DistributionPolicy.swift) sets `allowsDeveloperCloudFeatures` and `showsDeveloperTools` to false outside DEBUG builds. App Store Release operation is on-device. The app does not require the FastAPI service for calibration, practice, history, or local suggestions.

FastAPI is a separate debug sandbox under [backend/](../backend/README.md). Debug builds can opt into HTTP calls through [Core/BackendClient.swift](../Core/BackendClient.swift). [backend/app/main.py](../backend/app/main.py) exposes session, plan, and benchmark endpoints. The sandbox stores synthetic or approved test summaries in SQLite and writes runtime-event files. It is not part of the release app or the static website.

The adaptive profile is deterministic Swift code. This native flow does not call a hosted AI model. Backend container and Terraform files describe the separate sandbox deployment, not an iOS runtime dependency.

## Static publication and native distribution

Cloudflare Pages serves the checked-in `site/` HTML, images, and policy pages. It cannot run the SwiftUI app or the FastAPI service unchanged. Publishing the website does not build, sign, distribute, or approve an iOS app.

Native builds require full Xcode. Distribution also needs an Apple Developer team, signing, provisioning, and the relevant TestFlight or App Store process. See the [verification commands and limits](VERIFICATION.md) and [Pages publication procedure](deployment/CLOUDFLARE_PAGES.md).

## Source checks

The [shared-core CLI regression](../scripts/verify_cli.sh) compiles the Core sources without SwiftUI. The [App Store metadata validator](../scripts/validate_app_store_readiness.py) checks the declared release policy, privacy manifest, icons, and submission metadata. Neither check proves physical-device behavior or Apple approval.

The [architecture blueprint validator](../scripts/validate_architecture_blueprint.py) checks the separate architecture manifest's structure. A passing manifest check does not establish that every design proposal in other architecture documents is implemented.
