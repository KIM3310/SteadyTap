#!/usr/bin/env python3
"""Validate SteadyTap's repository-owned App Store submission surface."""

from __future__ import annotations

import json
import plistlib
import struct
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        FAILURES.append(message)


def read_text(relative_path: str) -> str:
    path = ROOT / relative_path
    require(path.is_file(), f"Missing required file: {relative_path}")
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def read_json(relative_path: str) -> dict:
    path = ROOT / relative_path
    require(path.is_file(), f"Missing required JSON: {relative_path}")
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        FAILURES.append(f"Invalid JSON in {relative_path}: {error}")
        return {}


def read_plist(relative_path: str) -> dict:
    path = ROOT / relative_path
    require(path.is_file(), f"Missing required plist: {relative_path}")
    if not path.is_file():
        return {}
    try:
        return plistlib.loads(path.read_bytes())
    except Exception as error:
        FAILURES.append(f"Invalid plist in {relative_path}: {error}")
        return {}


def png_dimensions(path: Path) -> tuple[int, int, int]:
    payload = path.read_bytes()[:26]
    require(payload[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG file: {path.relative_to(ROOT)}")
    if len(payload) < 26:
        return (0, 0, -1)
    width, height = struct.unpack(">II", payload[16:24])
    color_type = payload[25]
    return width, height, color_type


def validate_package() -> None:
    package = read_text("Package.swift")
    for fragment in (
        'bundleIdentifier: "com.kim.steadytap"',
        'displayVersion: "1.0"',
        'bundleVersion: "1"',
        'appIcon: .asset("AppIcon")',
        'appCategory: "public.app-category.utilities"',
        'additionalInfoPlistContentFilePath: "Resources/AdditionalInfo.plist"',
        '.process("Resources")',
    ):
        require(fragment in package, f"Package.swift is missing: {fragment}")
    require("appIcon: .placeholder" not in package, "Placeholder app icon is still configured")


def validate_xcode_project_definition() -> None:
    project = read_text("project.yml")
    for fragment in (
        "type: application",
        "platform: iOS",
        'deploymentTarget: "16.0"',
        "ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon",
        "INFOPLIST_FILE: Resources/SteadyTap-Info.plist",
        "MARKETING_VERSION: \"1.0\"",
        "CURRENT_PROJECT_VERSION: \"1\"",
        "PRODUCT_BUNDLE_IDENTIFIER: com.kim.steadytap",
        "SWIFT_VERSION: \"6.0\"",
        "TARGETED_DEVICE_FAMILY: \"1,2\"",
        "archive:",
    ):
        require(fragment in project, f"project.yml is missing: {fragment}")

    install_script = read_text("scripts/install_xcodegen.sh")
    require('version="2.45.4"' in install_script, "XcodeGen version must be pinned")
    require(
        'archive_sha256="090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef"'
        in install_script,
        "XcodeGen archive checksum must be pinned",
    )
    require(
        'binary_sha256="6aa2b4da95304b343bea12890c59f9655aa428c08b351d57d592cfab4e88a9f1"'
        in install_script,
        "XcodeGen binary checksum must be pinned",
    )

    info = read_plist("Resources/SteadyTap-Info.plist")
    require(info.get("CFBundlePackageType") == "APPL", "Native Info.plist must describe an app")
    require(info.get("CFBundleDisplayName") == "SteadyTap", "Native display name must be SteadyTap")
    require(
        info.get("ITSAppUsesNonExemptEncryption") is False,
        "Native Info.plist must declare exempt encryption usage",
    )
    require(info.get("LSRequiresIPhoneOS") is True, "Native Info.plist must require iPhone OS")
    require(
        set(info.get("UISupportedInterfaceOrientations", []))
        == {
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        },
        "iPhone orientation declarations are incomplete",
    )
    require(
        "UIInterfaceOrientationPortraitUpsideDown"
        in info.get("UISupportedInterfaceOrientations~ipad", []),
        "iPad orientation declarations are incomplete",
    )


def validate_icon_catalog() -> None:
    catalog = read_json("Resources/Assets.xcassets/AppIcon.appiconset/Contents.json")
    images = catalog.get("images", [])
    require(len(images) >= 18, "AppIcon catalog must cover iPhone, iPad, and marketing sizes")

    app_icon_dir = ROOT / "Resources/Assets.xcassets/AppIcon.appiconset"
    seen_marketing_icon = False
    for item in images:
        filename = item.get("filename")
        require(bool(filename), f"AppIcon entry has no filename: {item}")
        if not filename:
            continue
        icon_path = app_icon_dir / filename
        require(icon_path.is_file(), f"Missing AppIcon image: {filename}")
        if not icon_path.is_file():
            continue
        width, height, color_type = png_dimensions(icon_path)
        scale = int(str(item.get("scale", "1x")).removesuffix("x"))
        points = float(str(item.get("size", "0x0")).split("x", maxsplit=1)[0])
        expected = round(points * scale)
        require(
            (width, height) == (expected, expected),
            f"{filename} is {width}x{height}; expected {expected}x{expected}",
        )
        if item.get("idiom") == "ios-marketing":
            seen_marketing_icon = True
            require((width, height) == (1024, 1024), "Marketing icon must be 1024x1024")
            require(color_type not in {4, 6}, "Marketing icon must not contain an alpha channel")

    require(seen_marketing_icon, "AppIcon catalog has no ios-marketing image")


def validate_privacy_manifests() -> None:
    privacy = read_plist("Resources/PrivacyInfo.xcprivacy")
    require(privacy.get("NSPrivacyTracking") is False, "NSPrivacyTracking must be false")
    require(privacy.get("NSPrivacyCollectedDataTypes") == [], "Collected data types must be empty")
    accessed_types = privacy.get("NSPrivacyAccessedAPITypes", [])
    user_defaults_entries = [
        item
        for item in accessed_types
        if item.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"
    ]
    require(len(user_defaults_entries) == 1, "Privacy manifest must declare UserDefaults once")
    if user_defaults_entries:
        require(
            user_defaults_entries[0].get("NSPrivacyAccessedAPITypeReasons") == ["CA92.1"],
            "UserDefaults must use required reason CA92.1",
        )

    info = read_plist("Resources/AdditionalInfo.plist")
    require(
        info.get("ITSAppUsesNonExemptEncryption") is False,
        "AdditionalInfo.plist must declare exempt encryption usage",
    )


def is_https_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def validate_metadata() -> None:
    metadata = read_json("app-store/metadata.json")
    app = metadata.get("app", {})
    require(app.get("name") == "SteadyTap", "App name must match the product")
    require(app.get("bundleIdentifier") == "com.kim.steadytap", "Metadata bundle ID mismatch")
    require(app.get("version") == "1.0", "Metadata version mismatch")
    require(app.get("build") == "1", "Metadata build mismatch")
    require(app.get("primaryCategory") == "Utilities", "Primary category must be Utilities")

    locale = metadata.get("localizations", {}).get("en-US", {})
    require(1 <= len(locale.get("subtitle", "")) <= 30, "Subtitle must be 1-30 characters")
    require(len(locale.get("promotionalText", "")) <= 170, "Promotional text exceeds 170 characters")
    require(1 <= len(locale.get("description", "")) <= 4_000, "Description must be 1-4000 characters")
    require(1 <= len(locale.get("keywords", "")) <= 100, "Keywords must be 1-100 characters")
    for field in ("supportURL", "privacyPolicyURL", "marketingURL"):
        require(is_https_url(locale.get(field, "")), f"{field} must be a valid HTTPS URL")

    privacy = metadata.get("privacy", {})
    require(privacy.get("tracking") is False, "Metadata must declare no tracking")
    require(privacy.get("dataCollected") == [], "Metadata must declare no collected data")
    require(privacy.get("accountRequired") is False, "Metadata must declare no account")
    require(privacy.get("advertising") is False, "Metadata must declare no advertising")
    require(privacy.get("analytics") is False, "Metadata must declare no analytics")
    require(
        privacy.get("networkUploadInRelease") is False,
        "Metadata must declare no release network upload",
    )
    require(len(metadata.get("review", {}).get("notes", "")) >= 250, "Review notes are too short")


def validate_release_policy() -> None:
    policy = read_text("Core/DistributionPolicy.swift")
    require("#if DEBUG" in policy and "#else" in policy, "Distribution policy must branch on DEBUG")
    release_section = policy.split("#else", maxsplit=1)[1].split("#endif", maxsplit=1)[0]
    require(
        "allowsDeveloperCloudFeatures = false" in release_section,
        "Release policy must disable developer cloud features",
    )
    require(
        "showsDeveloperTools = false" in release_section,
        "Release policy must hide developer tools",
    )

    view_model = read_text("Core/AppViewModel.swift")
    require(
        view_model.count("guard DistributionPolicy.allowsDeveloperCloudFeatures") >= 5,
        "Network and sync entry points are not fully guarded",
    )
    require(
        "backendMode == .cloudPreferred" in view_model,
        "Upload queue must require explicit cloud mode",
    )

    intro = read_text("Views/IntroView.swift")
    for fragment in (
        "@Environment(\\.horizontalSizeClass)",
        "Clear Local Data",
        "DistributionPolicy.privacyPolicyURL",
        "DistributionPolicy.supportURL",
        "not a medical device",
        "quickStartMetrics",
        "quickStartActions",
        'Image(systemName: "\\(index + 1).circle.fill")',
    ):
        require(fragment in intro, f"Release UI is missing: {fragment}")
    require(
        "ScrollView(.horizontal" not in intro,
        "Release intro must not hide first-run steps in a horizontal scroller",
    )

    release_sources = "\n".join(
        read_text(path)
        for path in (
            "Views/IntroView.swift",
            "Views/ResultsView.swift",
            "Core/IntroQuickStartContent.swift",
        )
    )
    for banned in (
        "Production-grade",
        "Clinician Progress Report",
        "clinician progress report",
        "waveform.path.ecg",
        "localPrescriptionText",
    ):
        require(banned not in release_sources, f"Risky release copy remains: {banned}")


def validate_public_policy_pages() -> None:
    marketing_page = read_text("site/index.html")
    privacy_page = read_text("site/privacy/index.html")
    support_page = read_text("site/support/index.html")
    require("not a medical device" in marketing_page, "Marketing page lacks the purpose boundary")
    require("No tracking" in marketing_page, "Marketing page lacks the tracking boundary")
    for banned in ("coach handoff", "coaching layer", "intervention", "care team"):
        require(banned not in marketing_page.lower(), f"Marketing page contains risky claim: {banned}")
    require(
        (ROOT / "site/assets/steadytap-app-icon.png").is_file(),
        "Marketing page app icon is missing",
    )
    require("does not collect data" in privacy_page, "Public privacy policy lacks collection disclosure")
    require("Clear Local Data" in privacy_page, "Public privacy policy lacks deletion instructions")
    require("Private support" in support_page, "Support page lacks a private contact route")


def main() -> int:
    validate_package()
    validate_xcode_project_definition()
    validate_icon_catalog()
    validate_privacy_manifests()
    validate_metadata()
    validate_release_policy()
    validate_public_policy_pages()

    if FAILURES:
        print("App Store readiness validation failed:")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1

    print("App Store readiness validation passed.")
    print("- Native Xcode application target: iPhone and iPad Release archive scheme")
    print("- Release cloud features: disabled")
    print("- App icon catalog: iPhone, iPad, and 1024px marketing icon")
    print("- Privacy manifest: UserDefaults CA92.1; no tracking or collected data")
    print("- Metadata: lengths, URLs, privacy answers, and review notes validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
