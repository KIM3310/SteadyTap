# App Store Submission Checklist

## Verified in the repository

- [x] Stable bundle identifier, version, and build number
- [x] Original app icon asset with iPhone, iPad, and 1024px marketing sizes
- [x] Privacy manifest declaring `UserDefaults` reason `CA92.1`
- [x] Release build disables developer cloud and token controls
- [x] In-app privacy, support, purpose, and local-data deletion surfaces
- [x] Public privacy and support page sources with post-deploy content checks
- [x] English metadata and reviewer walkthrough
- [x] Automated metadata, icon, privacy-manifest, and release-policy validation
- [x] Native Xcode application target, unsigned iOS device Release `.app` CI build, and simulator launch smoke test

## App Store Connect owner steps

- [ ] Generate `SteadyTap.xcodeproj`, select the Apple Developer team, and complete signing
- [ ] Create or confirm the `com.kim.steadytap` app record
- [ ] Complete the age-rating questionnaire with the app's actual content
- [ ] Enter App Review contact name, phone, and email
- [ ] Confirm pricing, territories, tax, and agreements
- [ ] Upload production screenshots captured from the signed build
- [ ] Upload/select the signed build and answer export-compliance questions
- [ ] Run the reviewer path on a physical iPhone and iPad
- [ ] Submit the selected version for review

Do not add screenshots, claims, or privacy answers that differ from the submitted binary.
