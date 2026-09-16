from __future__ import annotations

import functools
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest
from http.client import HTTPConnection
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/pages_release.py"


class CleanURLHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        route = urlsplit(self.path).path
        path = Path(self.directory) / route.lstrip("/")
        if not path.suffix and not path.is_dir():
            self.path = route + ".html"
        super().do_GET()

    def log_message(self, *args):
        pass


class PagesReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.checkout = self.root / "checkout"
        self.site = self.checkout / "site"
        self.site.mkdir(parents=True)
        for source in (ROOT / "site").rglob("*.html"):
            target = self.site / source.relative_to(ROOT / "site")
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        (self.checkout / ".gitignore").write_text("site/revision.json\n")
        self.env = {
            "PATH": os.defpath,
            "HOME": str(self.root),
            "PYTHONDONTWRITEBYTECODE": "1",
            "GIT_AUTHOR_NAME": "Pages test",
            "GIT_AUTHOR_EMAIL": "pages-test@example.invalid",
            "GIT_COMMITTER_NAME": "Pages test",
            "GIT_COMMITTER_EMAIL": "pages-test@example.invalid",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GITHUB_STEP_SUMMARY": str(self.root / "summary.md"),
            "GITHUB_OUTPUT": str(self.root / "output.txt"),
        }
        self.git("init", "-q")
        self.git("add", ".")
        self.git("commit", "-qm", "test fixture")
        self.revision = self.git("rev-parse", "HEAD").strip()

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-C", str(self.checkout), *args], env=self.env, text=True,
        )

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args], env=self.env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30, check=False,
        )

    def prepare(self):
        result = self.run_cli("prepare", "--site", str(self.site), "--revision", self.revision)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Not deployed.", result.stdout)
        return json.loads((self.site / "revision.json").read_text())

    def serve(self):
        remote = self.root / "remote"
        shutil.copytree(self.site, remote)
        server = ThreadingHTTPServer(
            ("127.0.0.1", 0), functools.partial(CleanURLHandler, directory=str(remote)),
        )
        thread = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.01})
        thread.start()
        self.addCleanup(thread.join)
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        return remote, f"http://127.0.0.1:{server.server_port}"

    def verify(self, origin):
        return self.run_cli(
            "verify", "--site", str(self.site), "--revision", self.revision, "--origin", origin,
        )

    def request_fixture(self, origin, method, route):
        connection = HTTPConnection(urlsplit(origin).netloc, timeout=5)
        try:
            connection.request(method, route)
            response = connection.getresponse()
            return response.status, response.read()
        finally:
            connection.close()

    def test_http_fixture_rejects_file_links_outside_root(self):
        remote, origin = self.serve()
        sentinel = self.root / "remote-owned-sentinel.html"
        sentinel.write_bytes(b"OWNED TEST SENTINEL outside serving root\n")
        (remote / "guide.html").unlink()
        (remote / "guide.html").symlink_to(sentinel)
        for method in ("GET", "HEAD"):
            for route in ("/guide", "/guide.html"):
                with self.subTest(method=method, route=route):
                    status, body = self.request_fixture(origin, method, route)
                    self.assertEqual(status, 404, f"{method} {route} returned {status}: {body[:80]!r}")

    def test_http_fixture_rejects_directory_links_outside_root(self):
        remote, origin = self.serve()
        outside = self.root / "remote-owned-directory"
        outside.mkdir()
        (outside / "index.html").write_bytes(b"OWNED DIRECTORY SENTINEL outside serving root\n")
        (remote / "privacy/index.html").unlink()
        (remote / "privacy").rmdir()
        (remote / "privacy").symlink_to(outside, target_is_directory=True)
        for method in ("GET", "HEAD"):
            with self.subTest(method=method):
                status, body = self.request_fixture(origin, method, "/privacy/")
                self.assertEqual(status, 404, f"{method} /privacy/ returned {status}: {body[:80]!r}")

    def test_http_fixture_rejects_raw_and_encoded_parent_routes(self):
        _, origin = self.serve()
        (self.root / "guide").write_bytes(b"OWNED PARENT SENTINEL outside serving root\n")
        for method in ("GET", "HEAD"):
            for route in ("/../guide", "/%2e%2e/guide", "/..%2fguide", "/../guide.html", "/%2e%2e%2fguide.html"):
                with self.subTest(method=method, route=route):
                    status, body = self.request_fixture(origin, method, route)
                    self.assertEqual(status, 404, f"{method} {route} returned {status}: {body[:80]!r}")

    def test_push_without_credentials_reports_not_deployed(self):
        result = self.run_cli("prerequisites", "--event-name", "push")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Not deployed.", result.stdout)
        self.assertIn("Not deployed.", (self.root / "summary.md").read_text())
        self.assertEqual((self.root / "output.txt").read_text(), "ready=false\n")

    def test_explicit_release_fails_with_either_credential_missing(self):
        for present in (None, "CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID"):
            with self.subTest(present=present):
                for key in ("CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID"):
                    self.env.pop(key, None)
                if present:
                    self.env[present] = "synthetic-private-value"
                result = self.run_cli("prerequisites", "--event-name", "workflow_dispatch")
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("Not deployed.", result.stdout)
                self.assertNotIn("synthetic-private-value", result.stdout)
                self.assertNotIn("synthetic-private-value", (self.root / "summary.md").read_text())

    def test_credentials_enable_upload_without_claiming_deployment(self):
        self.env.update(CLOUDFLARE_API_TOKEN="synthetic-token", CLOUDFLARE_ACCOUNT_ID="synthetic-account")
        result = self.run_cli("prerequisites", "--event-name", "workflow_dispatch")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Upload not yet run.", result.stdout)
        self.assertEqual((self.root / "output.txt").read_text(), "ready=true\n")
        self.assertNotIn("synthetic-", result.stdout + (self.root / "summary.md").read_text())

    def test_prepared_manifest_matches_the_revision_and_all_eight_pages(self):
        payload = self.prepare()
        self.assertEqual(payload["revision"], self.revision)
        self.assertEqual(set(payload["pages"]), {
            "/", "/guide", "/architecture", "/verification", "/publisher", "/privacy/", "/support/", "/terms/",
        })
        self.assertEqual(payload["pages"]["/guide"], {
            "file": "guide.html", "sha256": hashlib.sha256((self.site / "guide.html").read_bytes()).hexdigest(),
        })
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_prepare_rejects_dirty_source(self):
        with (self.site / "guide.html").open("a") as stream:
            stream.write("local change")
        result = self.run_cli("prepare", "--site", str(self.site), "--revision", self.revision)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("requires a clean checkout", result.stdout)
        self.assertFalse((self.site / "revision.json").exists())

    def test_prepare_rejects_a_different_revision(self):
        result = self.run_cli("prepare", "--site", str(self.site), "--revision", "0" * 40)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("does not match HEAD", result.stdout)

    def test_http_verification_checks_real_page_bytes(self):
        self.prepare()
        remote, origin = self.serve()
        result = self.verify(origin)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("All eight page bytes match staged output.", result.stdout)
        self.assertIn(self.revision, result.stdout)
        with (remote / "architecture.html").open("a") as stream:
            stream.write("stale page")
        result = self.verify(origin)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("published page differs from staged output: /architecture", result.stdout)

    def test_http_verification_rejects_an_old_manifest(self):
        payload = self.prepare()
        remote, origin = self.serve()
        payload["revision"] = "0" * 40
        (remote / "revision.json").write_text(json.dumps(payload))
        result = self.verify(origin)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("published revision manifest does not match", result.stdout)

    def test_http_verification_rejects_a_missing_route(self):
        self.prepare()
        remote, origin = self.serve()
        (remote / "support/index.html").unlink()
        (remote / "support").rmdir()
        result = self.verify(origin)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("HTTP Error 404", result.stdout)

    def test_local_dispatch_delegates_auth_and_propagates_wrangler_failure(self):
        shutil.copyfile(ROOT / "Makefile", self.checkout / "Makefile")
        scripts = self.checkout / "scripts"
        scripts.mkdir()
        shutil.copyfile(SCRIPT, scripts / "pages_release.py")
        self.git("add", ".")
        self.git("commit", "-qm", "local dispatch fixture")
        revision = self.git("rev-parse", "HEAD").strip()
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        upload = bin_dir / "npx"
        upload.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$WRANGLER_ARGS"\n'
            'echo "Wrangler test double failed with exit 23" >&2\nexit 23\n'
        )
        upload.chmod(0o755)
        python = bin_dir / "python3"
        python.write_text(
            '#!/bin/sh\nif [ "$2" = verify ]; then\n'
            'echo "Unexpected post-failure verification" >&2\nexit 99\nfi\n'
            'exec "$TEST_PYTHON" "$@"\n'
        )
        python.chmod(0o755)
        arguments = self.root / "wrangler-args"
        env = dict(
            self.env, PATH=str(bin_dir) + os.pathsep + os.defpath,
            WRANGLER_ARGS=str(arguments), TEST_PYTHON=sys.executable,
        )
        result = subprocess.run(
            ["make", "--assume-old=verify-site", "deploy-pages"], cwd=self.checkout, env=env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30, check=False,
        )
        self.assertIn("Wrangler test double failed with exit 23", result.stdout)
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("Error 23", result.stdout)
        self.assertNotIn("Unexpected post-failure verification", result.stdout)
        self.assertEqual(arguments.read_text().splitlines(), [
            "--yes", "wrangler@4.114.0", "pages", "deploy", "site",
            "--project-name", "steadytap", "--branch=main", f"--commit-hash={revision}",
        ])
        self.assertEqual(json.loads((self.site / "revision.json").read_text())["revision"], revision)

    def test_static_preflight_failure_prevents_upload(self):
        workspace = self.root / "preflight"
        tests = workspace / "scripts/tests"
        tests.mkdir(parents=True)
        shutil.copyfile(ROOT / "Makefile", workspace / "Makefile")
        (tests / "test_failure.py").write_text(
            "import unittest\nclass InvalidSite(unittest.TestCase):\n"
            "    def test_invalid(self):\n        self.fail('intentional static validator failure')\n"
        )
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        upload = bin_dir / "npx"
        upload.write_text('#!/bin/sh\nprintf "upload invoked" > "$UPLOAD_MARKER"\n')
        upload.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + os.pathsep + os.defpath, UPLOAD_MARKER=str(self.root / "upload"))
        subprocess.run([str(upload)], env=env, check=True)
        self.assertEqual((self.root / "upload").read_text(), "upload invoked")
        (self.root / "upload").unlink()
        result = subprocess.run(
            ["make", "deploy-pages"], cwd=workspace, env=env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30, check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("intentional static validator failure", result.stdout)
        self.assertFalse((self.root / "upload").exists())


if __name__ == "__main__":
    unittest.main()
