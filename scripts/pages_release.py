#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.error import URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]


def report(message: str) -> None:
    print(message)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with Path(summary).open("a", encoding="utf-8") as stream:
            stream.write(message + "\n\n")


def prerequisites(event_name: str) -> int:
    missing = [
        name for name in ("CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID")
        if not os.environ.get(name, "").strip()
    ]
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a", encoding="utf-8") as stream:
            stream.write(f"ready={'false' if missing else 'true'}\n")
    if missing:
        report("Not deployed. Missing required configuration: " + ", ".join(missing) + ".")
        return 1 if event_name == "workflow_dispatch" else 0
    report("Upload not yet run. Required Cloudflare configuration is present.")
    return 0


def manifest(site: Path, revision: str) -> dict:
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("revision must be a full lowercase git SHA")
    pages = {}
    for path in sorted(site.rglob("*.html")):
        relative = path.relative_to(site)
        route = "/" + relative.as_posix()
        route = route[:-10] if path.name == "index.html" else route[:-5]
        pages[route] = {
            "file": relative.as_posix(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
    if len(pages) != 8 or "/" not in pages:
        raise ValueError("expected the eight SteadyTap HTML routes")
    return {"schema_version": 1, "revision": revision, "pages": pages}


def prepare(site: Path, revision: str) -> None:
    head = subprocess.check_output(
        ["git", "-C", str(site), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != head:
        raise ValueError("intended revision does not match HEAD")
    dirty = subprocess.check_output(
        ["git", "-C", str(site), "status", "--porcelain", "--untracked-files=all"], text=True
    ).strip()
    if dirty:
        raise ValueError("prepare requires a clean checkout; commit or remove local changes first")
    payload = manifest(site, revision)
    (site / "revision.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    report(f"Prepared eight pages for revision {revision}. Not deployed.")


def verify(site: Path, revision: str, origin: str) -> None:
    url = urlsplit(origin)
    if url.scheme not in {"http", "https"} or not url.netloc or url.query or url.fragment:
        raise ValueError("origin must be an HTTP(S) site URL without a query or fragment")
    if url.username or url.password or url.path not in {"", "/"}:
        raise ValueError("origin must not include credentials or a subpath")
    expected = manifest(site, revision)
    if json.loads((site / "revision.json").read_text(encoding="utf-8")) != expected:
        raise ValueError("local revision manifest does not match the staged pages")

    def fetch(route: str) -> bytes:
        request = Request(
            origin.rstrip("/") + route + "?revision=" + revision,
            headers={"Cache-Control": "no-cache"},
        )
        with urlopen(request, timeout=15) as response:
            return response.read()

    if json.loads(fetch("/revision.json")) != expected:
        raise ValueError("published revision manifest does not match the intended revision and pages")
    for route, page in expected["pages"].items():
        if hashlib.sha256(fetch(route)).hexdigest() != page["sha256"]:
            raise ValueError(f"published page differs from staged output: {route}")
    report(f"Verified {origin.rstrip('/')} at revision {revision}. All eight page bytes match staged output.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Pages prerequisites and revision evidence without uploading.")
    commands = parser.add_subparsers(dest="command", required=True)
    gate = commands.add_parser("prerequisites")
    gate.add_argument("--event-name", choices=("push", "workflow_dispatch"), required=True)
    for name in ("prepare", "verify"):
        command = commands.add_parser(name)
        command.add_argument("--site", type=Path, default=ROOT / "site")
        command.add_argument("--revision", required=True)
        if name == "verify":
            command.add_argument("--origin", required=True)
    args = parser.parse_args()
    try:
        if args.command == "prerequisites":
            return prerequisites(args.event_name)
        if args.command == "prepare":
            prepare(args.site.resolve(), args.revision)
        else:
            verify(args.site.resolve(), args.revision, args.origin)
    except (ValueError, OSError, URLError, subprocess.CalledProcessError) as error:
        report(f"Pages {args.command} failed. Publication is not verified. {error}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
