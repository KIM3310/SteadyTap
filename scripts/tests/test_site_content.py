from __future__ import annotations

import json
import unittest
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "site"


class Page(HTMLParser):
    def __init__(self, path: Path) -> None:
        super().__init__()
        self.text = ""
        self.descriptions = []
        self.links = []
        self.ids = set()
        self.json_ld = []
        self.hidden = None
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in {"script", "style"}:
            self.hidden = attrs.get("type", tag)
        if tag == "meta" and (
            attrs.get("name") == "description"
            or attrs.get("property") == "og:description"
        ):
            self.descriptions.append(attrs["content"])
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for attr in ("href", "src"):
            if attr in attrs:
                self.links.append(attrs[attr])

    def handle_endtag(self, tag):
        if tag in {"script", "style"}:
            self.hidden = None

    def handle_data(self, data):
        if self.hidden == "application/ld+json":
            self.json_ld.append(json.loads(data))
        elif self.hidden is None:
            self.text += data


class SiteContentTests(unittest.TestCase):
    def test_guide_metadata_describes_the_native_app(self):
        page = Page(SITE / "guide.html")
        descriptions = page.descriptions + [item["description"] for item in page.json_ld]
        self.assertEqual(len(descriptions), 3)
        for description in descriptions:
            with self.subTest(description=description):
                self.assertIn("touch-practice", description)
                self.assertIn("iPhone and iPad", description)
                self.assertNotIn("worksheet", description.lower())

    def test_public_guide_copy_does_not_offer_an_absent_worksheet(self):
        for name in ("index.html", "guide.html", "publisher.html"):
            page = Page(SITE / name)
            with self.subTest(page=name):
                self.assertFalse("worksheet" in page.text.lower(), f"{name} still offers a worksheet")
                self.assertIn("touch-practice", page.text)

    def test_architecture_names_the_native_flow_and_debug_boundary(self):
        sources = {
            "article": Page(SITE / "architecture.html").text,
            "source": (ROOT / "docs/system-architecture.md").read_text(),
        }
        for name, text in sources.items():
            for marker in (
                "SwiftUI", "Core/AppViewModel.swift", "Core/CalibrationEngine.swift",
                "Core/PersistenceStore.swift", "Core/DistributionPolicy.swift",
                "UserDefaults", "FastAPI", "separate debug sandbox", "Release",
            ):
                with self.subTest(source=name, marker=marker):
                    self.assertTrue(marker in text, f"{name} is missing {marker}")
            self.assertFalse("Python service or lab runtime" in text)

    def test_verification_explains_commands_and_native_limits(self):
        sources = {
            "article": Page(SITE / "verification.html").text,
            "source": (ROOT / "docs/VERIFICATION.md").read_text(),
        }
        for name, text in sources.items():
            for marker in (
                "./scripts/verify_cli.sh", "make verify-app-store", "make verify-backend",
                "Python 3.11+", "BOOTSTRAP_PYTHON", "full Xcode", "actool",
                "No physical iPhone/iPad test or App Store publication is claimed.",
                "ac5f099b2b553f1926a2fb6ffca05f8eee10b611",
                "cd0bf9f7601da0b81baeb53086e13ff99d4ac022",
            ):
                with self.subTest(source=name, marker=marker):
                    self.assertTrue(marker in text, f"{name} is missing {marker}")
            self.assertFalse("__pycache__" in text)
            self.assertFalse("Do not lead with this repository" in text)
        self.assertIn(
            "https://github.com/KIM3310/SteadyTap/blob/main/docs/VERIFICATION.md",
            Page(SITE / "verification.html").links,
        )

    def test_local_routes_fragments_and_source_links_resolve(self):
        pages = {path.resolve(): Page(path) for path in SITE.rglob("*.html")}
        self.assertEqual(len(pages), 8)
        checked = 0
        for source, page in pages.items():
            for link in page.links:
                url = urlsplit(link)
                repo_prefix = "/KIM3310/SteadyTap/blob/"
                with self.subTest(source=source.name, link=link):
                    if url.netloc == "github.com" and url.path.startswith(repo_prefix):
                        source_path = url.path[len(repo_prefix):].split("/", 1)[1]
                        self.assertTrue((ROOT / source_path).is_file(), source_path)
                        continue
                    if url.scheme or url.netloc:
                        continue
                    target = unquote(url.path)
                    path = (SITE / target.lstrip("/")) if target.startswith("/") else source.parent / target
                    if not target:
                        path = source
                    elif path.is_dir():
                        path /= "index.html"
                    elif not path.suffix:
                        path = path.with_suffix(".html")
                    self.assertTrue(path.is_file(), f"missing local target {link}")
                    if url.fragment:
                        self.assertIn(unquote(url.fragment), pages[path.resolve()].ids)
                    checked += 1
        self.assertGreater(checked, 80)


if __name__ == "__main__":
    unittest.main()
