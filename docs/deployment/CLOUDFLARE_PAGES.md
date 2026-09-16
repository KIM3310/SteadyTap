# Publish the static site on Cloudflare Pages

The checked-in configuration names the existing `steadytap` project and `https://steadytap.pages.dev/`. The output directory is `site/`. There is no site build step. Confirm the intended account and existing project before an authorized upload. This procedure does not create a project or change remote configuration.

Pages serves HTML, images, policies, and revision evidence. It does not run the SwiftUI app or the separate FastAPI debug sandbox. Website publication is not iOS distribution.

## Run local preflight without uploading

```sh
make verify-site
```

This command runs dependency-free content and publication regression tests, local link checks, the repository and architecture validators, and the metadata validator. It requires Python 3, Git, and Make. It does not require Cloudflare credentials, build an iOS app, or run the backend suite.

To exercise the GitHub workflow's missing-credential path without reading credential values, clear both variables for that process.

```sh
env -u CLOUDFLARE_API_TOKEN -u CLOUDFLARE_ACCOUNT_ID python3 scripts/pages_release.py prerequisites --event-name push
env -u CLOUDFLARE_API_TOKEN -u CLOUDFLARE_ACCOUNT_ID python3 scripts/pages_release.py prerequisites --event-name workflow_dispatch
```

The push check prints `Not deployed.` and exits successfully. The explicit dispatch check prints `Not deployed.` and fails. In GitHub Actions, both write the result to the job summary and set `ready=false`. Ordinary preflight checks remain independent of publication credentials.

## Prepare revision evidence without uploading

Commit the intended changes first. From a clean checkout, run these commands.

```sh
python3 scripts/pages_release.py prepare --revision "$(git rev-parse HEAD)"
```

Preparation rejects a dirty checkout or a revision that differs from HEAD. It writes the ignored `site/revision.json` file with the full git revision and SHA256 hashes for all eight HTML routes. This generated file belongs in the upload, not in a source commit. Preparation reports `Not deployed.` because it does not contact Cloudflare.

## Upload only after publication approval

The [Pages workflow](../../.github/workflows/pages-auto-deploy.yml) runs static preflight before its upload job. The job checks the presence of `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` without printing their values. A push with missing configuration skips upload and writes an explicit summary. A manually requested GitHub workflow run fails if either value is missing.

For an approved manual production upload to the configured project, run this command from the intended clean revision.

```sh
make deploy-pages
```

Both the workflow and this target use Wrangler `4.114.0` and the existing `steadytap` project on the `main` production branch. The local target runs static preflight, prepares the clean revision manifest, calls Wrangler, then checks the published bytes. There is no project-creation step.

The local target delegates authentication to Wrangler, including an existing OAuth login. It does not impose the GitHub workflow's environment-variable gate. Wrangler authentication or upload failures stop the target and prevent post-upload verification.

## Verify the published revision and content

After an authorized upload, run the same comparison used by CI.

```sh
python3 scripts/pages_release.py verify --revision "$(git rev-parse HEAD)" --origin https://steadytap.pages.dev
```

Verification first checks that the local manifest matches the staged HTML. It then fetches `/revision.json` and all eight page routes with a revision query and a no-cache request. The remote manifest and every page hash must match the staged files. This includes the home, guide, architecture, verification, publisher, privacy, support, and terms pages.

An older manifest, stale editorial page, missing route, or HTTP failure exits nonzero. The job summary states that publication is not verified. A failed post-upload check does not roll back the upload. Inspect the remote revision before deciding whether to retry an approved deployment.

## Evidence limits

The [baseline Pages run](https://github.com/KIM3310/SteadyTap/actions/runs/34193067771) for `cd0bf9f7601da0b81baeb53086e13ff99d4ac022` reported success but skipped upload. That historical run is not evidence that these pages were deployed. A successful local preflight or generated revision file is not evidence of an upload either.

The [native verification limits](../VERIFICATION.md) remain separate. No physical-device test, signed iOS release, or App Store publication follows from a Pages check.
