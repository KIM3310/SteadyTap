#!/usr/bin/env python3
"""Validate the repository architecture surface.

The check is intentionally dependency-free so active and archived repositories can
run the same guard in CI. It verifies public-facing docs, local links, architecture
blueprint hooks, and neutral technical positioning.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any, NoReturn, cast

ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"
ARCH_DOC = ROOT / "docs" / "cloud-ai-architecture.md"
ARCH_MANIFEST = ROOT / "docs" / "architecture" / "blueprint.json"
ARCH_VALIDATOR = ROOT / "scripts" / "validate_architecture_blueprint.py"
ARCH_WORKFLOW = ROOT / ".github" / "workflows" / "architecture-blueprint.yml"
DOCS_SERVICE_OFFER = ROOT / "docs" / "service-offer.json"
SITE_SERVICE_OFFER = ROOT / "site" / "service-offer.json"
SITE_INDEX = ROOT / "site" / "index.html"
SITE_LLMS = ROOT / "site" / "llms.txt"
PRIVATE_INQUIRY_URL = (
    "https://kim3310-doeon-kim-portfolio.pages.dev/"
    "?offer=SteadyTap&inquiry=consumer-prototype-customization#private-inquiry"
)

REQUIRED_FILES = (
    README,
    ROOT / ".editorconfig",
    ROOT / "CONTRIBUTING.md",
    ARCH_DOC,
    ARCH_MANIFEST,
    ARCH_VALIDATOR,
    ARCH_WORKFLOW,
    DOCS_SERVICE_OFFER,
    SITE_SERVICE_OFFER,
    SITE_INDEX,
    SITE_LLMS,
)

BANNED_TERMS = {
    "hir" + "ing",
    "recr" + "uiter",
    "job" + " seeker",
    "job" + "-seeker",
    "inter" + "view prep",
    "career" + " signal",
    "best" + " fit roles",
    "role" + "-fit",
    "role" + "_fit",
    "cover" + " letter",
    "job" + " description",
    "required" + " qualifications",
    "preferred" + " qualifications",
    "채" + "용",
    "취" + "업",
    "구" + "직",
    "입" + "사",
}

LOCAL_PATH_MARKERS = (
    "/Users/",
    "/home/",
    "C:/Users/",
    "C:\\Users\\",
    "file://",
    "vscode://",
)

MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]\n]+\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")


def fail(message: str) -> NoReturn:
    print(f"repository surface validation failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def require_file(path: Path) -> None:
    if not path.exists() or not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")


def markdown_files() -> list[Path]:
    files = sorted(ROOT.glob("*.md"))
    docs = ROOT / "docs"
    if docs.exists():
        files.extend(sorted(docs.rglob("*.md")))
    return files


TEXT_SUFFIXES = {
    ".css",
    ".go",
    ".js",
    ".json",
    ".html",
    ".jsonl",
    ".jsx",
    ".md",
    ".mjs",
    ".py",
    ".rs",
    ".sh",
    ".sql",
    ".swift",
    ".toml",
    ".ts",
    ".tsx",
    ".yml",
    ".yaml",
}

SKIP_FILENAMES = {
    "Cargo.lock",
    "Pipfile.lock",
    "package-lock.json",
    "pnpm-lock.yaml",
    "poetry.lock",
    "uv.lock",
    "yarn.lock",
}

SKIP_PARTS = {
    ".git",
    ".mypy_cache",
    ".next",
    ".pytest_cache",
    ".ruff_cache",
    ".venv",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "node_modules",
}


def is_skipped(path: Path) -> bool:
    relative = path.relative_to(ROOT)
    has_skipped_name = path.name in SKIP_FILENAMES
    has_skipped_part = any(part in SKIP_PARTS for part in relative.parts)
    return has_skipped_name or has_skipped_part


def code_and_generated_files() -> list[Path]:
    candidates: list[Path] = []
    for path in sorted(ROOT.rglob("*")):
        is_text_file = path.is_file() and path.suffix in TEXT_SUFFIXES
        if is_text_file and not is_skipped(path):
            candidates.append(path)
    return candidates


def is_external_or_route(target: str) -> bool:
    lowered = target.lower()
    is_external = lowered.startswith(("http://", "https://", "mailto:", "tel:"))
    is_anchor = target.startswith("#")
    has_local_path_marker = False
    for marker in LOCAL_PATH_MARKERS:
        if target.startswith(marker):
            has_local_path_marker = True
            break
    is_absolute_route = target.startswith("/") and not has_local_path_marker
    return is_external or is_anchor or is_absolute_route


def check_local_link(source: Path, target: str, line: int) -> None:
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    for marker in LOCAL_PATH_MARKERS:
        if marker in target:
            fail(f"local machine path in {source.relative_to(ROOT)}:{line}: {target}")
    if is_external_or_route(target):
        return
    path_part = target.split("#", 1)[0]
    if not path_part:
        return
    candidate = (source.parent / path_part).resolve()
    try:
        candidate.relative_to(ROOT.resolve())
    except ValueError:
        fail(f"link escapes repository in {source.relative_to(ROOT)}:{line}: {target}")
    if not candidate.exists():
        fail(f"broken local link in {source.relative_to(ROOT)}:{line}: {target}")


def check_markdown_links() -> None:
    for path in markdown_files():
        text = read_text(path)
        for match in MARKDOWN_LINK_RE.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            check_local_link(path, match.group(1).strip(), line)


def scan_positioning_terms() -> None:
    paths = markdown_files() + code_and_generated_files()
    for path in paths:
        text = read_text(path).lower()
        for term in BANNED_TERMS:
            if term.lower() in text:
                fail(f"non-neutral positioning term in {path.relative_to(ROOT)}")


def load_manifest() -> dict[str, Any]:
    try:
        loaded = json.loads(ARCH_MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid architecture manifest JSON: {exc}")
    if not isinstance(loaded, dict):
        fail("architecture manifest root must be an object")
    return cast(dict[str, Any], loaded)


def load_json(path: Path) -> dict[str, Any]:
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(ROOT)}: {exc}")
    if not isinstance(loaded, dict):
        fail(f"{path.relative_to(ROOT)} root must be an object")
    return cast(dict[str, Any], loaded)


def check_service_offer_surface() -> None:
    docs_offer = load_json(DOCS_SERVICE_OFFER)
    site_offer = load_json(SITE_SERVICE_OFFER)
    if docs_offer != site_offer:
        fail("docs/service-offer.json and site/service-offer.json must match")

    commerce = docs_offer.get("commerce")
    if not isinstance(commerce, dict):
        fail("service offer missing commerce object")
    checkout = commerce.get("checkout")
    if not isinstance(checkout, dict):
        fail("service offer missing checkout object")
    structured = docs_offer.get("structured_data")
    if not isinstance(structured, dict):
        fail("service offer missing structured_data object")

    expectations: tuple[tuple[str, Any, Any], ...] = (
        ("lead_capture_url", docs_offer.get("lead_capture_url"), PRIVATE_INQUIRY_URL),
        ("commerce.lane_id", commerce.get("lane_id"), "consumer-prototype-customization"),
        ("commerce.billing_mode", commerce.get("billing_mode"), "one-time"),
        ("commerce.checkout.provider", checkout.get("provider"), None),
        ("commerce.checkout.status", checkout.get("status"), "not-configured"),
        ("commerce.checkout.fallback_url", checkout.get("fallback_url"), PRIVATE_INQUIRY_URL),
        ("commerce.sponsorship.eligible", commerce.get("sponsorship", {}).get("eligible"), False),
        ("commerce.advertising.eligible", commerce.get("advertising", {}).get("eligible"), False),
        ("structured_data.applicationCategory", structured.get("applicationCategory"), "AccessibilityApplication"),
    )
    for label, actual, expected in expectations:
        if actual != expected:
            fail(f"{label} mismatch: expected {expected!r}, got {actual!r}")

    public_surface = "\n".join(
        read_text(path)
        for path in (
            README,
            ROOT / "docs" / "search-growth-implementation.md",
            DOCS_SERVICE_OFFER,
            SITE_SERVICE_OFFER,
            SITE_INDEX,
            SITE_LLMS,
        )
    )
    required_markers = (
        "fixed-scope private prototype customization",
        "consumer-prototype-customization",
        PRIVATE_INQUIRY_URL,
        "no checkout provider is configured",
    )
    for marker in required_markers:
        if marker not in public_surface:
            fail(f"service surface missing marker: {marker}")
    banned_claims = (
        "GitHub Issue Form",
        "premium progress history",
        "organization dashboard",
        "private calibration templates",
        "SteadyTap health tool",
        "Clinical path",
        "clinical path",
        "Clinician-first",
    )
    for marker in banned_claims:
        if marker in public_surface:
            fail(f"service surface contains unsupported marker: {marker}")


def check_architecture_surface() -> None:
    manifest = load_manifest()
    required = {
        "schema_version",
        "repository",
        "neutrality",
        "focus",
        "cloud_architecture",
        "ai_engineering",
        "validation",
        "research_grounding",
    }
    missing = required - set(manifest)
    if missing:
        fail(f"architecture manifest missing keys: {', '.join(sorted(missing))}")

    readme = read_text(README)
    for expected in (
        "docs/cloud-ai-architecture.md",
        "docs/architecture/blueprint.json",
        "scripts/validate_architecture_blueprint.py",
    ):
        if expected not in readme:
            fail(f"README missing architecture reference: {expected}")


def main() -> None:
    for path in REQUIRED_FILES:
        require_file(path)
    if not read_text(README).strip():
        fail("README.md is empty")
    check_architecture_surface()
    check_service_offer_surface()
    check_markdown_links()
    scan_positioning_terms()
    print("repository surface validation ok")


if __name__ == "__main__":
    main()
